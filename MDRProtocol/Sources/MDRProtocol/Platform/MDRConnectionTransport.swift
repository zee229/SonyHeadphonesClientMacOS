import Foundation

/// Protocol abstracting the Bluetooth connection lifecycle.
/// Extends MDRTransport (send/receive) with connect/disconnect/poll.
public protocol MDRConnectionTransport: MDRTransport {
    var connectionState: BluetoothConnectionState { get }
    var lastError: String { get }

    func connect(macAddress: String)
    func disconnect()
    @discardableResult func poll(timeoutMS: Int) -> BluetoothConnectionState
    func pairedDevices() -> [MDRBluetoothDevice]
}

/// Mock connection transport for testing.
/// Allows scripting connection state transitions.
public final class MockConnectionTransport: MDRConnectionTransport {
    public private(set) var connectionState: BluetoothConnectionState = .disconnected
    public private(set) var lastError: String = ""

    // Recording
    public var sentData: [Data] = []
    public var receiveQueue: [Data] = []
    public var connectCalls: [String] = []
    public var disconnectCount: Int = 0
    public var pollCount: Int = 0

    // Scriptable behavior
    public var onConnect: ((String) -> Void)?
    public var nextPollState: BluetoothConnectionState?
    public var deviceList: [MDRBluetoothDevice] = []

    public init() {}

    // MARK: - MDRConnectionTransport

    public func connect(macAddress: String) {
        connectCalls.append(macAddress)
        connectionState = .connecting
        lastError = ""
        onConnect?(macAddress)
    }

    public func disconnect() {
        disconnectCount += 1
        connectionState = .disconnected
    }

    @discardableResult
    public func poll(timeoutMS: Int) -> BluetoothConnectionState {
        pollCount += 1
        if let next = nextPollState {
            connectionState = next
        }
        return connectionState
    }

    public func pairedDevices() -> [MDRBluetoothDevice] {
        deviceList
    }

    // MARK: - MDRTransport

    public func send(_ data: Data) throws -> Int {
        sentData.append(data)
        return data.count
    }

    public func receive(maxLength: Int) throws -> Data {
        if receiveQueue.isEmpty { return Data() }
        return receiveQueue.removeFirst()
    }

    // MARK: - Test helpers

    /// Set the transport to immediately error on connect.
    public func setConnectError(_ message: String) {
        onConnect = { [weak self] _ in
            self?.lastError = message
            self?.connectionState = .error(message)
        }
    }

    /// Simulate successful connection on next poll.
    public func setConnectSuccess() {
        nextPollState = .connected
    }

    /// Simulate connection failure on next poll.
    public func setPollError(_ message: String) {
        nextPollState = .error(message)
        lastError = message
    }

    /// Simulate disconnect on next poll.
    public func setPollDisconnected(_ message: String = "") {
        nextPollState = .disconnected
        lastError = message
    }
}
