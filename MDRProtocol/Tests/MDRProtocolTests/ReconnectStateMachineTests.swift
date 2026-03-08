import Testing
import Foundation
@testable import MDRProtocol

// MARK: - ReconnectStateMachine Tests

@Suite("ReconnectStateMachine")
struct ReconnectStateMachineTests {

    // MARK: - Initial State

    @Test func initialStateIsInactive() {
        let sm = ReconnectStateMachine()
        #expect(sm.isActive == false)
        #expect(sm.attempt == 0)
        #expect(sm.deviceMac == "")
        #expect(sm.deviceName == "")
    }

    // MARK: - shouldReconnect

    @Test func shouldReconnectWithValidMac() {
        #expect(ReconnectStateMachine.shouldReconnect(deviceMac: "AA:BB:CC:DD:EE:FF", isManualDisconnect: false) == true)
    }

    @Test func shouldNotReconnectWithEmptyMac() {
        #expect(ReconnectStateMachine.shouldReconnect(deviceMac: "", isManualDisconnect: false) == false)
    }

    @Test func shouldNotReconnectOnManualDisconnect() {
        #expect(ReconnectStateMachine.shouldReconnect(deviceMac: "AA:BB:CC:DD:EE:FF", isManualDisconnect: true) == false)
    }

    @Test func shouldNotReconnectEmptyMacAndManual() {
        #expect(ReconnectStateMachine.shouldReconnect(deviceMac: "", isManualDisconnect: true) == false)
    }

    // MARK: - handleDisconnect

    @Test func handleDisconnectStartsReconnect() {
        var sm = ReconnectStateMachine()
        let action = sm.handleDisconnect(deviceMac: "AA:BB:CC", deviceName: "WH-1000XM5")

        #expect(sm.isActive == true)
        #expect(sm.attempt == 1)
        #expect(sm.deviceMac == "AA:BB:CC")
        #expect(sm.deviceName == "WH-1000XM5")

        if case .scheduleRetry(let delay, let attempt, let maxAttempts) = action {
            #expect(attempt == 1)
            #expect(maxAttempts == 30)
            #expect(delay == 2.0) // baseDelay * 2^0
        } else {
            Issue.record("Expected .scheduleRetry, got \(action)")
        }
    }

    // MARK: - Exponential Backoff

    @Test func exponentialBackoffDelays() {
        let sm = ReconnectStateMachine(baseDelay: 2.0, maxDelay: 60.0)

        #expect(sm.delay(forAttempt: 1) == 2.0)    // 2 * 2^0
        #expect(sm.delay(forAttempt: 2) == 4.0)    // 2 * 2^1
        #expect(sm.delay(forAttempt: 3) == 8.0)    // 2 * 2^2
        #expect(sm.delay(forAttempt: 4) == 16.0)   // 2 * 2^3
        #expect(sm.delay(forAttempt: 5) == 32.0)   // 2 * 2^4
        #expect(sm.delay(forAttempt: 6) == 60.0)   // capped at maxDelay
        #expect(sm.delay(forAttempt: 7) == 60.0)   // stays capped
        #expect(sm.delay(forAttempt: 100) == 60.0)  // still capped
    }

    @Test func customDelayParameters() {
        let sm = ReconnectStateMachine(baseDelay: 1.0, maxDelay: 10.0)
        #expect(sm.delay(forAttempt: 1) == 1.0)
        #expect(sm.delay(forAttempt: 2) == 2.0)
        #expect(sm.delay(forAttempt: 3) == 4.0)
        #expect(sm.delay(forAttempt: 4) == 8.0)
        #expect(sm.delay(forAttempt: 5) == 10.0) // capped
    }

    @Test func backoffProgressesThroughAttempts() {
        var sm = ReconnectStateMachine(baseDelay: 2.0, maxDelay: 60.0, maxAttempts: 10)
        let _ = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "Test")

        var delays: [TimeInterval] = []
        // Attempt 1 already happened in handleDisconnect
        if case .scheduleRetry(let delay, _, _) = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "Test") {
            delays.append(delay)
        }

        // Simulate failures and collect delays
        for _ in 0..<5 {
            if case .scheduleRetry(let delay, _, _) = sm.handleConnectFailed() {
                delays.append(delay)
            }
        }

        // First delay is 2.0 (attempt 1), then 4, 8, 16, 32, 60
        #expect(delays[0] == 2.0)
        #expect(delays[1] == 4.0)
        #expect(delays[2] == 8.0)
        #expect(delays[3] == 16.0)
        #expect(delays[4] == 32.0)
        #expect(delays[5] == 60.0)
    }

    // MARK: - timerFired

    @Test func timerFiredReturnsAttemptConnect() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "AA:BB:CC", deviceName: "Test")

        let action = sm.timerFired()
        #expect(action == .attemptConnect(mac: "AA:BB:CC"))
    }

    @Test func timerFiredWhenInactiveReturnsNone() {
        var sm = ReconnectStateMachine()
        let action = sm.timerFired()
        #expect(action == .none)
    }

    // MARK: - handleConnectFailed

    @Test func handleConnectFailedSchedulesRetry() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "Test")
        #expect(sm.attempt == 1)

        let action = sm.handleConnectFailed()
        #expect(sm.attempt == 2)

        if case .scheduleRetry(let delay, let attempt, _) = action {
            #expect(attempt == 2)
            #expect(delay == 4.0) // 2 * 2^1
        } else {
            Issue.record("Expected .scheduleRetry, got \(action)")
        }
    }

    @Test func handleConnectFailedWhenInactiveReturnsNone() {
        var sm = ReconnectStateMachine()
        let action = sm.handleConnectFailed()
        #expect(action == .none)
    }

    // MARK: - handleDeviceNotFound

    @Test func handleDeviceNotFoundSchedulesRetry() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "Test")

        let action = sm.handleDeviceNotFound()
        #expect(sm.attempt == 2)

        if case .scheduleRetry(_, let attempt, _) = action {
            #expect(attempt == 2)
        } else {
            Issue.record("Expected .scheduleRetry, got \(action)")
        }
    }

    @Test func handleDeviceNotFoundWhenInactiveReturnsNone() {
        var sm = ReconnectStateMachine()
        let action = sm.handleDeviceNotFound()
        #expect(action == .none)
    }

    // MARK: - handleConnected

    @Test func handleConnectedResetsState() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "Test")
        #expect(sm.isActive == true)

        let action = sm.handleConnected()
        #expect(action == .none)
        #expect(sm.isActive == false)
        #expect(sm.attempt == 0)
        #expect(sm.deviceMac == "")
        #expect(sm.deviceName == "")
    }

    // MARK: - cancel

    @Test func cancelResetsAndReturnsDiscovery() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "Test")
        #expect(sm.isActive == true)

        let action = sm.cancel()
        #expect(action == .resetToDiscovery)
        #expect(sm.isActive == false)
        #expect(sm.attempt == 0)
    }

    @Test func cancelWhenInactiveStillReturnsDiscovery() {
        var sm = ReconnectStateMachine()
        let action = sm.cancel()
        #expect(action == .resetToDiscovery)
    }

    // MARK: - Max Attempts Exhausted

    @Test func givesUpAfterMaxAttempts() {
        var sm = ReconnectStateMachine(baseDelay: 1.0, maxDelay: 1.0, maxAttempts: 3)
        let _ = sm.handleDisconnect(deviceMac: "AA:BB", deviceName: "WH-1000XM5")

        // Attempt 1 was in handleDisconnect
        let action2 = sm.handleConnectFailed() // attempt 2
        if case .scheduleRetry(_, let attempt, _) = action2 {
            #expect(attempt == 2)
        } else {
            Issue.record("Expected .scheduleRetry for attempt 2")
        }

        let action3 = sm.handleConnectFailed() // attempt 3
        if case .scheduleRetry(_, let attempt, _) = action3 {
            #expect(attempt == 3)
        } else {
            Issue.record("Expected .scheduleRetry for attempt 3")
        }

        let action4 = sm.handleConnectFailed() // attempt 4 > maxAttempts(3)
        #expect(action4 == .giveUp(error: "Could not reconnect to WH-1000XM5 after 3 attempts"))
        #expect(sm.isActive == false)
    }

    @Test func givesUpMessage() {
        var sm = ReconnectStateMachine(maxAttempts: 1)
        let _ = sm.handleDisconnect(deviceMac: "X", deviceName: "My Headphones")

        let action = sm.handleConnectFailed()
        if case .giveUp(let error) = action {
            #expect(error.contains("My Headphones"))
            #expect(error.contains("1 attempts"))
        } else {
            Issue.record("Expected .giveUp")
        }
    }

    // MARK: - Full Reconnect Cycle

    @Test func fullSuccessfulReconnectCycle() {
        var sm = ReconnectStateMachine(baseDelay: 2.0, maxDelay: 60.0, maxAttempts: 30)

        // 1. Disconnect happens
        let action1 = sm.handleDisconnect(deviceMac: "AA:BB:CC", deviceName: "WH-1000XM5")
        if case .scheduleRetry(let delay, let attempt, _) = action1 {
            #expect(delay == 2.0)
            #expect(attempt == 1)
        } else {
            Issue.record("Expected .scheduleRetry")
        }

        // 2. Timer fires
        let action2 = sm.timerFired()
        #expect(action2 == .attemptConnect(mac: "AA:BB:CC"))

        // 3. Connection succeeds
        let action3 = sm.handleConnected()
        #expect(action3 == .none)
        #expect(sm.isActive == false)
    }

    @Test func reconnectCycleWithFailuresBeforeSuccess() {
        var sm = ReconnectStateMachine(baseDelay: 1.0, maxDelay: 10.0, maxAttempts: 5)

        // Disconnect
        let _ = sm.handleDisconnect(deviceMac: "MAC", deviceName: "Headphones")
        #expect(sm.attempt == 1)

        // Fail 1 → timer → attempt → fail
        let _ = sm.timerFired()
        let a2 = sm.handleConnectFailed()
        #expect(sm.attempt == 2)
        if case .scheduleRetry(let delay, _, _) = a2 {
            #expect(delay == 2.0) // 1 * 2^1
        }

        // Fail 2 → timer → attempt → device not found
        let _ = sm.timerFired()
        let a3 = sm.handleDeviceNotFound()
        #expect(sm.attempt == 3)
        if case .scheduleRetry(let delay, _, _) = a3 {
            #expect(delay == 4.0) // 1 * 2^2
        }

        // Fail 3 → timer → attempt → success!
        let _ = sm.timerFired()
        let a4 = sm.handleConnected()
        #expect(a4 == .none)
        #expect(sm.isActive == false)
        #expect(sm.attempt == 0)
    }

    @Test func reconnectCycleCancelledMidway() {
        var sm = ReconnectStateMachine(maxAttempts: 10)
        let _ = sm.handleDisconnect(deviceMac: "MAC", deviceName: "Test")
        let _ = sm.handleConnectFailed() // attempt 2
        let _ = sm.handleConnectFailed() // attempt 3
        #expect(sm.attempt == 3)

        let action = sm.cancel()
        #expect(action == .resetToDiscovery)
        #expect(sm.isActive == false)
    }

    // MARK: - Edge Cases

    @Test func maxAttemptsOfOne() {
        var sm = ReconnectStateMachine(maxAttempts: 1)
        let action1 = sm.handleDisconnect(deviceMac: "X", deviceName: "Dev")
        if case .scheduleRetry(_, let attempt, _) = action1 {
            #expect(attempt == 1)
        }

        // Next failure exhausts
        let action2 = sm.handleConnectFailed()
        if case .giveUp(_) = action2 {
            // Expected
        } else {
            Issue.record("Expected .giveUp after max 1 attempt")
        }
    }

    @Test func restartAfterGiveUp() {
        var sm = ReconnectStateMachine(maxAttempts: 1)
        let _ = sm.handleDisconnect(deviceMac: "A", deviceName: "Dev1")
        let _ = sm.handleConnectFailed() // gives up
        #expect(sm.isActive == false)

        // Can start again with a new device
        let action = sm.handleDisconnect(deviceMac: "B", deviceName: "Dev2")
        #expect(sm.isActive == true)
        #expect(sm.deviceMac == "B")
        #expect(sm.deviceName == "Dev2")
        #expect(sm.attempt == 1)
        if case .scheduleRetry(_, _, _) = action {} else {
            Issue.record("Expected .scheduleRetry after restart")
        }
    }

    @Test func restartAfterCancel() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "A", deviceName: "Dev1")
        let _ = sm.cancel()
        #expect(sm.isActive == false)

        let action = sm.handleDisconnect(deviceMac: "B", deviceName: "Dev2")
        #expect(sm.isActive == true)
        #expect(sm.attempt == 1)
        if case .scheduleRetry(_, _, _) = action {} else {
            Issue.record("Expected .scheduleRetry after restart")
        }
    }

    @Test func restartAfterSuccess() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "A", deviceName: "Dev1")
        let _ = sm.handleConnected()

        let action = sm.handleDisconnect(deviceMac: "A", deviceName: "Dev1")
        #expect(sm.attempt == 1)
        if case .scheduleRetry(_, _, _) = action {} else {
            Issue.record("Expected .scheduleRetry")
        }
    }

    @Test func handleConnectFailedAfterGiveUpDoesNothing() {
        var sm = ReconnectStateMachine(maxAttempts: 1)
        let _ = sm.handleDisconnect(deviceMac: "A", deviceName: "Dev")
        let _ = sm.handleConnectFailed() // gives up, isActive = false

        let action = sm.handleConnectFailed()
        #expect(action == .none) // not active, so no-op
    }

    @Test func timerFiredAfterCancelDoesNothing() {
        var sm = ReconnectStateMachine()
        let _ = sm.handleDisconnect(deviceMac: "A", deviceName: "Dev")
        let _ = sm.cancel()

        let action = sm.timerFired()
        #expect(action == .none)
    }

    // MARK: - Equatable

    @Test func equatable() {
        let a = ReconnectStateMachine(baseDelay: 2.0, maxDelay: 60.0, maxAttempts: 30)
        let b = ReconnectStateMachine(baseDelay: 2.0, maxDelay: 60.0, maxAttempts: 30)
        #expect(a == b)
    }

    @Test func defaultValues() {
        let sm = ReconnectStateMachine()
        #expect(sm.baseDelay == 2.0)
        #expect(sm.maxDelay == 60.0)
        #expect(sm.maxAttempts == 30)
    }
}

// MARK: - MockConnectionTransport Tests

@Suite("MockConnectionTransport")
struct MockConnectionTransportTests {

    @Test func initialState() {
        let mock = MockConnectionTransport()
        if case .disconnected = mock.connectionState {} else {
            Issue.record("Expected .disconnected")
        }
        #expect(mock.lastError == "")
        #expect(mock.connectCalls.isEmpty)
        #expect(mock.disconnectCount == 0)
        #expect(mock.pollCount == 0)
    }

    @Test func connectRecordsCalls() {
        let mock = MockConnectionTransport()
        mock.connect(macAddress: "AA:BB:CC")

        #expect(mock.connectCalls.count == 1)
        #expect(mock.connectCalls[0] == "AA:BB:CC")
        if case .connecting = mock.connectionState {} else {
            Issue.record("Expected .connecting after connect()")
        }
    }

    @Test func disconnectRecords() {
        let mock = MockConnectionTransport()
        mock.disconnect()
        mock.disconnect()
        #expect(mock.disconnectCount == 2)
    }

    @Test func pollReturnsScriptedState() {
        let mock = MockConnectionTransport()
        mock.nextPollState = .connected
        let state = mock.poll(timeoutMS: 0)
        if case .connected = state {} else {
            Issue.record("Expected .connected from poll")
        }
        #expect(mock.pollCount == 1)
    }

    @Test func setConnectErrorSetsErrorState() {
        let mock = MockConnectionTransport()
        mock.setConnectError("Device not found")
        mock.connect(macAddress: "AA:BB")

        if case .error(let msg) = mock.connectionState {
            #expect(msg == "Device not found")
        } else {
            Issue.record("Expected .error state")
        }
    }

    @Test func pairedDevicesReturnsConfiguredList() {
        let mock = MockConnectionTransport()
        mock.deviceList = [
            MDRBluetoothDevice(name: "WH-1000XM5", macAddress: "AA:BB:CC"),
            MDRBluetoothDevice(name: "AirPods", macAddress: "DD:EE:FF"),
        ]

        let devices = mock.pairedDevices()
        #expect(devices.count == 2)
        #expect(devices[0].name == "WH-1000XM5")
        #expect(devices[1].macAddress == "DD:EE:FF")
    }

    @Test func sendAndReceive() throws {
        let mock = MockConnectionTransport()
        let sent = try mock.send(Data([1, 2, 3]))
        #expect(sent == 3)
        #expect(mock.sentData.count == 1)

        mock.receiveQueue.append(Data([10, 20]))
        let received = try mock.receive(maxLength: 100)
        #expect(received == Data([10, 20]))
    }

    @Test func receiveEmptyWhenNoData() throws {
        let mock = MockConnectionTransport()
        let data = try mock.receive(maxLength: 100)
        #expect(data.isEmpty)
    }
}

// MARK: - ReconnectAction Equatable Tests

@Suite("ReconnectAction")
struct ReconnectActionTests {

    @Test func noneEquality() {
        #expect(ReconnectAction.none == ReconnectAction.none)
    }

    @Test func scheduleRetryEquality() {
        #expect(ReconnectAction.scheduleRetry(delay: 2.0, attempt: 1, maxAttempts: 30)
            == ReconnectAction.scheduleRetry(delay: 2.0, attempt: 1, maxAttempts: 30))
        #expect(ReconnectAction.scheduleRetry(delay: 2.0, attempt: 1, maxAttempts: 30)
            != ReconnectAction.scheduleRetry(delay: 4.0, attempt: 2, maxAttempts: 30))
    }

    @Test func attemptConnectEquality() {
        #expect(ReconnectAction.attemptConnect(mac: "AA") == ReconnectAction.attemptConnect(mac: "AA"))
        #expect(ReconnectAction.attemptConnect(mac: "AA") != ReconnectAction.attemptConnect(mac: "BB"))
    }

    @Test func giveUpEquality() {
        #expect(ReconnectAction.giveUp(error: "fail") == ReconnectAction.giveUp(error: "fail"))
        #expect(ReconnectAction.giveUp(error: "a") != ReconnectAction.giveUp(error: "b"))
    }

    @Test func differentCasesNotEqual() {
        #expect(ReconnectAction.none != ReconnectAction.resetToDiscovery)
        #expect(ReconnectAction.attemptConnect(mac: "A") != ReconnectAction.giveUp(error: "A"))
    }
}
