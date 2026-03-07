import Foundation

/// A length-prefixed array of non-POD elements that implement MDRReadWritable.
/// Matches C++ `MDRArray<T>` from Protocol.hpp.
public struct MDRArray<Element: MDRReadWritable & Equatable>: Equatable, Sendable, MDRReadWritable {
    public var value: [Element]

    public init(_ value: [Element] = []) {
        self.value = value
    }

    public static func read(from reader: inout DataReader) throws -> MDRArray {
        let count = try reader.readUInt8()
        var result: [Element] = []
        result.reserveCapacity(Int(count))
        for _ in 0..<count {
            result.append(try Element.read(from: &reader))
        }
        return MDRArray(result)
    }

    public func write(to writer: inout DataWriter) {
        precondition(value.count <= 255, "MDRArray too long")
        writer.writeUInt8(UInt8(value.count))
        for elem in value {
            elem.write(to: &writer)
        }
    }

    public var count: Int { value.count }
}

/// A fixed-size array of non-POD elements that implement MDRReadWritable.
/// Matches C++ `MDRFixedArray<T, Size>` from Protocol.hpp.
/// Unlike MDRArray, this does NOT have a length prefix byte.
public struct MDRFixedArray<Element: MDRReadWritable & Equatable>: Equatable, Sendable {
    public var value: [Element]
    public let fixedCount: Int

    public init(count: Int, defaultValue: Element) {
        self.fixedCount = count
        self.value = Array(repeating: defaultValue, count: count)
    }

    public init(_ value: [Element]) {
        self.fixedCount = value.count
        self.value = value
    }

    public static func read(from reader: inout DataReader, count: Int) throws -> MDRFixedArray {
        var result: [Element] = []
        result.reserveCapacity(count)
        for _ in 0..<count {
            result.append(try Element.read(from: &reader))
        }
        return MDRFixedArray(result)
    }

    public func write(to writer: inout DataWriter) {
        for elem in value {
            elem.write(to: &writer)
        }
    }
}
