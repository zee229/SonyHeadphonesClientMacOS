import Foundation

/// A length-prefixed array of fixed-size POD elements (1 byte each).
/// Matches C++ `MDRPodArray<UInt8>` from Protocol.hpp.
/// For multi-byte POD elements, use the generic read/write with element size.
public struct PodArray<Element: FixedWidthInteger & Sendable>: Equatable, Sendable, MDRReadWritable {
    public var value: [Element]

    public init(_ value: [Element] = []) {
        self.value = value
    }

    public static func read(from reader: inout DataReader) throws -> PodArray {
        let count = try reader.readUInt8()
        let elementSize = MemoryLayout<Element>.size
        var result: [Element] = []
        result.reserveCapacity(Int(count))
        for _ in 0..<count {
            let bytes = try reader.readBytes(count: elementSize)
            // Read big-endian for multi-byte, direct for UInt8
            if elementSize == 1 {
                result.append(Element(bytes[bytes.startIndex]))
            } else {
                // Big-endian read
                var val: Element = 0
                for byte in bytes {
                    val = val << 8 | Element(byte)
                }
                result.append(val)
            }
        }
        return PodArray(result)
    }

    public func write(to writer: inout DataWriter) {
        precondition(value.count <= 255, "PodArray too long")
        let elementSize = MemoryLayout<Element>.size
        writer.writeUInt8(UInt8(value.count))
        for elem in value {
            if elementSize == 1 {
                writer.writeUInt8(UInt8(truncatingIfNeeded: elem))
            } else {
                // Big-endian write
                for i in stride(from: (elementSize - 1) * 8, through: 0, by: -8) {
                    writer.writeUInt8(UInt8(truncatingIfNeeded: elem >> i))
                }
            }
        }
    }

    public var count: Int { value.count }
}
