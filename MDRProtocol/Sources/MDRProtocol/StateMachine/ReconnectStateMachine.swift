import Foundation

/// Action produced by the reconnect state machine.
public enum ReconnectAction: Equatable {
    /// No action needed.
    case none
    /// Schedule a timer with the given delay, then call `timerFired()`.
    case scheduleRetry(delay: TimeInterval, attempt: Int, maxAttempts: Int)
    /// Attempt to connect now (look up device, call transport.connect).
    case attemptConnect(mac: String)
    /// Max retries exhausted — show error.
    case giveUp(error: String)
    /// Cancel complete — go to discovery.
    case resetToDiscovery
}

/// Pure state machine for reconnect logic. No timers, no I/O — just state transitions.
///
/// Usage flow:
/// 1. Call `handleDisconnect(...)` when connection drops unexpectedly
/// 2. Machine returns `.scheduleRetry(delay:...)` — caller sets a timer
/// 3. When timer fires, call `timerFired()` — returns `.attemptConnect(mac:)`
/// 4. Caller attempts connection. On failure, call `handleConnectFailed()` — loops back to step 2
/// 5. On success, call `handleConnected()` — resets state
/// 6. User can call `cancel()` at any time
public struct ReconnectStateMachine: Equatable {
    public private(set) var attempt: Int = 0
    public private(set) var deviceMac: String = ""
    public private(set) var deviceName: String = ""
    public var isActive: Bool { attempt > 0 }

    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let maxAttempts: Int

    public init(baseDelay: TimeInterval = 2.0, maxDelay: TimeInterval = 60.0, maxAttempts: Int = 30) {
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.maxAttempts = maxAttempts
    }

    /// Determines whether auto-reconnect should be attempted.
    public static func shouldReconnect(deviceMac: String, isManualDisconnect: Bool) -> Bool {
        !deviceMac.isEmpty && !isManualDisconnect
    }

    /// Start reconnecting to a device. Returns the first scheduling action.
    public mutating func handleDisconnect(deviceMac: String, deviceName: String) -> ReconnectAction {
        self.deviceMac = deviceMac
        self.deviceName = deviceName
        self.attempt = 0
        return scheduleNext()
    }

    /// Connection attempt failed — schedule another retry.
    public mutating func handleConnectFailed() -> ReconnectAction {
        guard isActive else { return .none }
        return scheduleNext()
    }

    /// Device not found in paired list — schedule another retry.
    public mutating func handleDeviceNotFound() -> ReconnectAction {
        guard isActive else { return .none }
        return scheduleNext()
    }

    /// Successfully connected — reset state.
    public mutating func handleConnected() -> ReconnectAction {
        reset()
        return .none
    }

    /// User cancelled reconnect.
    public mutating func cancel() -> ReconnectAction {
        reset()
        return .resetToDiscovery
    }

    /// Timer fired — time to attempt connection.
    public mutating func timerFired() -> ReconnectAction {
        guard isActive else { return .none }
        return .attemptConnect(mac: deviceMac)
    }

    /// Calculate delay for a given attempt number.
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        min(baseDelay * pow(2.0, Double(attempt - 1)), maxDelay)
    }

    // MARK: - Private

    private mutating func scheduleNext() -> ReconnectAction {
        attempt += 1
        if attempt > maxAttempts {
            let name = deviceName
            let max = maxAttempts
            reset()
            return .giveUp(error: "Could not reconnect to \(name) after \(max) attempts")
        }
        let delay = delay(forAttempt: attempt)
        return .scheduleRetry(delay: delay, attempt: attempt, maxAttempts: maxAttempts)
    }

    private mutating func reset() {
        attempt = 0
        deviceMac = ""
        deviceName = ""
    }
}
