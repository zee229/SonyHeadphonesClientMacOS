import Foundation

/// Append-style binary writer.
/// Replaces C++ `UInt8** ppDstBuffer` pattern.
public struct DataWriter: Sendable {
    public private(set) var data: Data

    public init(capacity: Int = 64) {
        data = Data()
        data.reserveCapacity(capacity)
    }

    public mutating func writeUInt8(_ value: UInt8) {
        data.append(value)
    }

    public mutating func writeInt8(_ value: Int8) {
        data.append(UInt8(bitPattern: value))
    }

    public mutating func writeInt16BE(_ value: Int16BE) {
        data.append(value.byte0)
        data.append(value.byte1)
    }

    public mutating func writeInt24BE(_ value: Int24BE) {
        data.append(value.byte0)
        data.append(value.byte1)
        data.append(value.byte2)
    }

    public mutating func writeInt32BE(_ value: Int32BE) {
        data.append(value.byte0)
        data.append(value.byte1)
        data.append(value.byte2)
        data.append(value.byte3)
    }

    public mutating func writeData(_ d: Data) {
        data.append(d)
    }

    public mutating func writeBytes(_ bytes: [UInt8]) {
        data.append(contentsOf: bytes)
    }
}
