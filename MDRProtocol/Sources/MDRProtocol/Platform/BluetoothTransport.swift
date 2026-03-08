import Foundation
import IOBluetooth

/// Discovered Bluetooth device info.
public struct MDRBluetoothDevice: Sendable {
    public let name: String
    public let macAddress: String

    public init(name: String, macAddress: String) {
        self.name = name
        self.macAddress = macAddress
    }
}

/// Connection state for BluetoothTransport.
public enum BluetoothConnectionState: Sendable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

/// Sony MDR service UUID (96956C7B-26D4-9A4B-A8B0-3FB17D393CB6E2).
public let kMDRServiceUUID = "956C7B26-D49A-4BA8-B03F-B17D393CB6E2"

/// IOBluetooth RFCOMM transport for Sony MDR headphones.
/// Implements MDRTransport for send/receive, plus connect/disconnect/poll.
///
/// Not thread-safe for send/receive. Buffer access is locked for delegate callbacks.
public final class BluetoothTransport: NSObject, MDRConnectionTransport, IOBluetoothRFCOMMChannelDelegate {
    // MARK: - State

    public private(set) var connectionState: BluetoothConnectionState = .disconnected
    public private(set) var lastError: String = ""

    // MARK: - Private

    private var rfcommChannel: IOBluetoothRFCOMMChannel?
    private var buffer = Data()
    private let lock = NSLock()

    // MARK: - MDRTransport

    public func send(_ data: Data) throws -> Int {
        guard let channel = rfcommChannel, case .connected = connectionState else {
            return 0
        }
        let result = data.withUnsafeBytes { ptr in
            channel.writeAsync(UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
                               length: UInt16(data.count), refcon: nil)
        }
        if result != kIOReturnSuccess {
            throw MDRError.protocolError("RFCOMM write failed: 0x\(String(result, radix: 16))")
        }
        return data.count
    }

    public func receive(maxLength: Int) throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        guard !buffer.isEmpty else { return Data() }
        let len = min(maxLength, buffer.count)
        let result = buffer.prefix(len)
        buffer.removeFirst(len)
        return Data(result)
    }

    // MARK: - Connect

    /// Connect to a device by MAC address (protocol conformance).
    public func connect(macAddress: String) {
        connect(macAddress: macAddress, serviceUUID: kMDRServiceUUID)
    }

    /// Connect to a device by MAC address and service UUID.
    /// This is asynchronous — call `poll()` to drive the connection.
    public func connect(macAddress: String, serviceUUID: String) {
        connectionState = .connecting
        lastError = ""

        guard let device = IOBluetoothDevice(addressString: macAddress) else {
            lastError = "Device not found (not paired?)"
            connectionState = .error(lastError)
            return
        }

        guard let uuidData = parseUUID(serviceUUID) else {
            lastError = "Invalid UUID string"
            connectionState = .error(lastError)
            return
        }

        let sdpUUID = IOBluetoothSDPUUID(data: uuidData)
        guard let serviceRecord = device.getServiceRecord(for: sdpUUID) else {
            lastError = "Service not found on device (try checking Bluetooth settings/ensure paired)"
            connectionState = .error(lastError)
            return
        }

        var channelID: BluetoothRFCOMMChannelID = 0
        guard serviceRecord.getRFCOMMChannelID(&channelID) == kIOReturnSuccess else {
            lastError = "Could not get RFCOMM Channel ID from service record"
            connectionState = .error(lastError)
            return
        }

        var channel: IOBluetoothRFCOMMChannel?
        let result = device.openRFCOMMChannelAsync(&channel, withChannelID: channelID, delegate: self)
        if result != kIOReturnSuccess {
            lastError = "Failed to open RFCOMM channel: 0x\(String(result, radix: 16))"
            connectionState = .error(lastError)
            return
        }

        rfcommChannel = channel
    }

    // MARK: - Disconnect

    public func disconnect() {
        rfcommChannel?.close()
        rfcommChannel = nil
        connectionState = .disconnected
    }

    // MARK: - Poll

    /// Run the NSRunLoop briefly to process IOBluetooth events.
    /// Returns the current connection state.
    @discardableResult
    public func poll(timeoutMS: Int = 0) -> BluetoothConnectionState {
        var seconds = Double(max(timeoutMS, 0)) / 1000.0
        if seconds <= 0 { seconds = 0.0001 }
        let limitDate = Date(timeIntervalSinceNow: seconds)
        RunLoop.current.run(mode: .default, before: limitDate)
        return connectionState
    }

    // MARK: - Device Discovery

    /// Returns a list of paired Bluetooth devices (instance method for protocol conformance).
    public func pairedDevices() -> [MDRBluetoothDevice] {
        Self.pairedDevices()
    }

    /// Returns a list of paired Bluetooth devices.
    public static func pairedDevices() -> [MDRBluetoothDevice] {
        guard let devices = IOBluetoothDevice.pairedDevices() else { return [] }
        return devices.compactMap { item -> MDRBluetoothDevice? in
            guard let device = item as? IOBluetoothDevice else { return nil }
            let name = device.name ?? ""
            let addr = (device.addressString ?? "").replacingOccurrences(of: "-", with: ":")
            return MDRBluetoothDevice(name: name, macAddress: addr)
        }
    }

    // MARK: - IOBluetoothRFCOMMChannelDelegate

    public func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        if error != kIOReturnSuccess {
            lastError = "Connection handshake failed: 0x\(String(error, radix: 16))"
            connectionState = .error(lastError)
            self.rfcommChannel = nil
            return
        }
        connectionState = .connected
    }

    public func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!,
                                   data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let data = Data(bytes: dataPointer, count: dataLength)
        lock.lock()
        buffer.append(data)
        lock.unlock()
    }

    public func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        if lastError.isEmpty {
            lastError = "Connection closed by remote"
        }
        connectionState = .disconnected
        self.rfcommChannel = nil
    }

    // MARK: - UUID Parsing

    /// Parse a UUID string like "956C7B26-D49A-4BA8-B03F-B17D393CB6E2" into 16 bytes.
    private func parseUUID(_ string: String) -> Data? {
        let hex = string.replacingOccurrences(of: "-", with: "")
        guard hex.count == 32 else { return nil }
        var data = Data(capacity: 16)
        var index = hex.startIndex
        for _ in 0..<16 {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        return data
    }
}
