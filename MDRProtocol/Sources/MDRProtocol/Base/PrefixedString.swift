import Foundation

/// A string prefixed with a 1-byte length. Max length 127.
/// Matches C++ `MDRPrefixedString` from Protocol.hpp.
public struct PrefixedString: Equatable, Sendable, MDRReadWritable {
    public var value: String

    public init(_ value: String = "") {
        self.value = value
    }

    public static func read(from reader: inout DataReader) throws -> PrefixedString {
        let len = try reader.readUInt8()
        guard len < 128 else {
            throw MDRError.invalidValue("PrefixedString length \(len) >= 128")
        }
        let bytes = try reader.readBytes(count: Int(len))
        guard let str = String(data: bytes, encoding: .utf8) else {
            throw MDRError.invalidValue("PrefixedString contains invalid UTF-8")
        }
        return PrefixedString(str)
    }

    public func write(to writer: inout DataWriter) {
        let utf8 = Array(value.utf8)
        precondition(utf8.count < 128, "PrefixedString too long")
        writer.writeUInt8(UInt8(utf8.count))
        writer.writeBytes(utf8)
    }

    public var count: Int { value.utf8.count }
}

extension PrefixedString: CustomStringConvertible {
    public var description: String { value }
}
