import Foundation

/// Wraps `Data` with a read cursor for sequential, bounds-checked reads.
/// Replaces C++ `const UInt8** ppSrcBuffer` pattern.
public struct DataReader: ~Copyable, Sendable {
    public let data: Data
    public private(set) var offset: Int

    public init(_ data: Data) {
        self.data = data
        self.offset = 0
    }

    public var remaining: Int { data.count - offset }

    public mutating func readUInt8() throws -> UInt8 {
        guard remaining >= 1 else { throw MDRError.notEnoughData }
        let value = data[data.startIndex + offset]
        offset += 1
        return value
    }

    public mutating func readInt8() throws -> Int8 {
        Int8(bitPattern: try readUInt8())
    }

    public mutating func readInt16BE() throws -> Int16BE {
        guard remaining >= 2 else { throw MDRError.notEnoughData }
        let start = data.startIndex + offset
        let result = Int16BE(Int16(bitPattern:
            UInt16(data[start]) << 8 | UInt16(data[start + 1])
        ))
        offset += 2
        return result
    }

    public mutating func readInt24BE() throws -> Int24BE {
        guard remaining >= 3 else { throw MDRError.notEnoughData }
        let start = data.startIndex + offset
        var result = Int24BE()
        result.byte0 = data[start]
        result.byte1 = data[start + 1]
        result.byte2 = data[start + 2]
        offset += 3
        return result
    }

    public mutating func readInt32BE() throws -> Int32BE {
        guard remaining >= 4 else { throw MDRError.notEnoughData }
        let start = data.startIndex + offset
        let result = Int32BE(Int32(bitPattern:
            UInt32(data[start]) << 24 |
            UInt32(data[start + 1]) << 16 |
            UInt32(data[start + 2]) << 8 |
            UInt32(data[start + 3])
        ))
        offset += 4
        return result
    }

    public mutating func readBytes(count: Int) throws -> Data {
        guard remaining >= count else { throw MDRError.notEnoughData }
        let start = data.startIndex + offset
        let result = data[start..<start + count]
        offset += count
        return Data(result)
    }

    /// Peek at remaining data without advancing the cursor.
    public func peekRemaining() -> Data {
        Data(data[(data.startIndex + offset)...])
    }
}
