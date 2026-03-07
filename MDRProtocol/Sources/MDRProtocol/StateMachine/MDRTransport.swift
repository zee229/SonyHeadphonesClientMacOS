import Foundation

/// Protocol abstracting the Bluetooth transport layer.
/// Implementations must be non-blocking.
public protocol MDRTransport: AnyObject {
    /// Send data to the device. Returns the number of bytes actually sent.
    /// Returns 0 if unable to send right now.
    func send(_ data: Data) throws -> Int

    /// Receive data from the device. Returns empty Data if no data available.
    func receive(maxLength: Int) throws -> Data
}

/// Mock transport for testing. Stores sent data and returns queued receive data.
public final class MockTransport: MDRTransport {
    public var sentData: [Data] = []
    public var receiveQueue: [Data] = []

    public init() {}

    public func send(_ data: Data) throws -> Int {
        sentData.append(data)
        return data.count
    }

    public func receive(maxLength: Int) throws -> Data {
        if receiveQueue.isEmpty { return Data() }
        return receiveQueue.removeFirst()
    }
}
