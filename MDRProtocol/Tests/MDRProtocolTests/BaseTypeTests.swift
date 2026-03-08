import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Int16BE Tests

@Suite("Int16BE")
struct Int16BETests {
    @Test func zeroRoundtrip() {
        let v = Int16BE(0)
        #expect(v.value == 0)
        #expect(v.byte0 == 0)
        #expect(v.byte1 == 0)
    }

    @Test func positiveRoundtrip() {
        let v = Int16BE(1)
        #expect(v.value == 1)
        #expect(v.byte0 == 0)
        #expect(v.byte1 == 1)
    }

    @Test func negativeRoundtrip() {
        let v = Int16BE(-1)
        #expect(v.value == -1)
        #expect(v.byte0 == 0xFF)
        #expect(v.byte1 == 0xFF)
    }

    @Test func maxPositiveRoundtrip() {
        let v = Int16BE(0x7FFF)
        #expect(v.value == 0x7FFF)
        #expect(v.byte0 == 0x7F)
        #expect(v.byte1 == 0xFF)
    }

    @Test func minNegativeRoundtrip() {
        let v = Int16BE(-0x8000)
        #expect(v.value == -0x8000)
        #expect(v.byte0 == 0x80)
        #expect(v.byte1 == 0x00)
    }

    @Test func byteOrder() {
        let v = Int16BE(0x0102)
        #expect(v.byte0 == 0x01)
        #expect(v.byte1 == 0x02)
    }

    @Test func writerReaderRoundtrip() throws {
        let original = Int16BE(12345)
        var writer = DataWriter()
        writer.writeInt16BE(original)
        #expect(writer.data.count == 2)

        var reader = DataReader(writer.data)
        let restored = try reader.readInt16BE()
        #expect(restored == original)
        #expect(restored.value == 12345)
    }
}

// MARK: - Int24BE Tests

@Suite("Int24BE")
struct Int24BETests {
    @Test func zeroRoundtrip() {
        let v = Int24BE(0)
        #expect(v.value == 0)
    }

    @Test func oneRoundtrip() {
        let v = Int24BE(1)
        #expect(v.byte0 == 1)
        #expect(v.byte1 == 0)
        #expect(v.byte2 == 1) // C++ bug replicated
        #expect(v.value == 0x10001)
    }

    @Test func writerReaderRoundtrip() throws {
        let original = Int24BE(42)
        var writer = DataWriter()
        writer.writeInt24BE(original)
        #expect(writer.data.count == 3)

        var reader = DataReader(writer.data)
        let restored = try reader.readInt24BE()
        #expect(restored == original)
    }
}

// MARK: - Int32BE Tests

@Suite("Int32BE")
struct Int32BETests {
    @Test func zeroRoundtrip() {
        let v = Int32BE(0)
        #expect(v.value == 0)
        #expect(v.byte0 == 0 && v.byte1 == 0 && v.byte2 == 0 && v.byte3 == 0)
    }

    @Test func oneRoundtrip() {
        let v = Int32BE(1)
        #expect(v.value == 1)
        #expect(v.byte3 == 1)
    }

    @Test func negativeRoundtrip() {
        let v = Int32BE(-1)
        #expect(v.value == -1)
        #expect(v.byte0 == 0xFF && v.byte1 == 0xFF && v.byte2 == 0xFF && v.byte3 == 0xFF)
    }

    @Test func maxPositiveRoundtrip() {
        let v = Int32BE(0x7FFFFFFF)
        #expect(v.value == 0x7FFFFFFF)
        #expect(v.byte0 == 0x7F)
    }

    @Test func byteOrder() {
        let v = Int32BE(0x01020304)
        #expect(v.byte0 == 0x01)
        #expect(v.byte1 == 0x02)
        #expect(v.byte2 == 0x03)
        #expect(v.byte3 == 0x04)
    }

    @Test func setterRoundtrip() {
        var v = Int32BE()
        v.value = 999
        #expect(v.value == 999)
    }

    @Test func writerReaderRoundtrip() throws {
        let original = Int32BE(0x12345678)
        var writer = DataWriter()
        writer.writeInt32BE(original)
        #expect(writer.data.count == 4)

        var reader = DataReader(writer.data)
        let restored = try reader.readInt32BE()
        #expect(restored == original)
        #expect(restored.value == 0x12345678)
    }
}

// MARK: - DataReader Tests

@Suite("DataReader")
struct DataReaderTests {
    @Test func readPastEnd() throws {
        var reader = DataReader(Data([0x01]))
        _ = try reader.readUInt8()
        #expect(throws: MDRError.self) { try reader.readUInt8() }
    }

    @Test func readInt16BEPastEnd() {
        var reader = DataReader(Data([0x01]))
        #expect(throws: MDRError.self) { try reader.readInt16BE() }
    }

    @Test func readInt32BEPastEnd() {
        var reader = DataReader(Data([0x01, 0x02]))
        #expect(throws: MDRError.self) { try reader.readInt32BE() }
    }

    @Test func readBytesPastEnd() {
        var reader = DataReader(Data([0x01, 0x02]))
        #expect(throws: MDRError.self) { try reader.readBytes(count: 3) }
    }

    @Test func remainingTracking() throws {
        var reader = DataReader(Data([0x01, 0x02, 0x03]))
        #expect(reader.remaining == 3)
        _ = try reader.readUInt8()
        #expect(reader.remaining == 2)
        _ = try reader.readBytes(count: 2)
        #expect(reader.remaining == 0)
    }

    @Test func emptyData() {
        let reader = DataReader(Data())
        #expect(reader.remaining == 0)
    }

    @Test func readUInt8Sequence() throws {
        var reader = DataReader(Data([0xAA, 0xBB, 0xCC]))
        #expect(try reader.readUInt8() == 0xAA)
        #expect(try reader.readUInt8() == 0xBB)
        #expect(try reader.readUInt8() == 0xCC)
    }

    @Test func readInt8() throws {
        var reader = DataReader(Data([0xFF]))
        #expect(try reader.readInt8() == -1)
    }
}

// MARK: - DataWriter Tests

@Suite("DataWriter")
struct DataWriterTests {
    @Test func writeMultipleTypes() throws {
        var writer = DataWriter()
        writer.writeUInt8(0x42)
        writer.writeInt16BE(Int16BE(0x0102))
        writer.writeInt32BE(Int32BE(0x03040506))
        #expect(writer.data.count == 7)

        var reader = DataReader(writer.data)
        #expect(try reader.readUInt8() == 0x42)
        #expect(try reader.readInt16BE().value == 0x0102)
        #expect(try reader.readInt32BE().value == 0x03040506)
    }

    @Test func writeDataBlob() {
        var writer = DataWriter()
        writer.writeData(Data([0x01, 0x02, 0x03]))
        #expect(writer.data == Data([0x01, 0x02, 0x03]))
    }

    @Test func writeBytesArray() {
        var writer = DataWriter()
        writer.writeBytes([0xAA, 0xBB])
        #expect(writer.data == Data([0xAA, 0xBB]))
    }
}

// MARK: - PrefixedString Tests

@Suite("PrefixedString")
struct PrefixedStringTests {
    @Test func emptyRoundtrip() throws {
        let original = PrefixedString("")
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data == Data([0x00]))

        var reader = DataReader(writer.data)
        let restored = try PrefixedString.read(from: &reader)
        #expect(restored == original)
    }

    @Test func helloRoundtrip() throws {
        let original = PrefixedString("hello")
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 6)
        #expect(writer.data[0] == 5)

        var reader = DataReader(writer.data)
        let restored = try PrefixedString.read(from: &reader)
        #expect(restored.value == "hello")
    }

    @Test func maxLengthRoundtrip() throws {
        let str = String(repeating: "A", count: 127)
        let original = PrefixedString(str)
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 128)
        #expect(writer.data[0] == 127)

        var reader = DataReader(writer.data)
        let restored = try PrefixedString.read(from: &reader)
        #expect(restored.value == str)
    }

    @Test func invalidLengthOnRead() {
        var reader = DataReader(Data([128]))
        #expect(throws: (any Error).self) { try PrefixedString.read(from: &reader) }
    }

    @Test func count() {
        #expect(PrefixedString("hello").count == 5)
    }
}

// MARK: - PodArray Tests

@Suite("PodArray")
struct PodArrayTests {
    @Test func emptyRoundtrip() throws {
        let original = PodArray<UInt8>([])
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data == Data([0x00]))

        var reader = DataReader(writer.data)
        let restored = try PodArray<UInt8>.read(from: &reader)
        #expect(restored.value == [])
    }

    @Test func simpleRoundtrip() throws {
        let original = PodArray<UInt8>([1, 2, 3])
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data == Data([3, 1, 2, 3]))

        var reader = DataReader(writer.data)
        let restored = try PodArray<UInt8>.read(from: &reader)
        #expect(restored.value == [1, 2, 3])
    }

    @Test func maxCountRoundtrip() throws {
        let arr: [UInt8] = (0..<255).map { UInt8($0 & 0xFF) }
        let original = PodArray<UInt8>(arr)
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 256)

        var reader = DataReader(writer.data)
        let restored = try PodArray<UInt8>.read(from: &reader)
        #expect(restored.value == arr)
    }

    @Test func countProperty() {
        #expect(PodArray<UInt8>([10, 20]).count == 2)
    }
}

// MARK: - MDRArray Tests

@Suite("MDRArray")
struct MDRArrayTests {
    @Test func emptyRoundtrip() throws {
        let original = MDRArray<PrefixedString>([])
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data == Data([0x00]))

        var reader = DataReader(writer.data)
        let restored = try MDRArray<PrefixedString>.read(from: &reader)
        #expect(restored.value == [])
    }

    @Test func stringsRoundtrip() throws {
        let original = MDRArray<PrefixedString>([
            PrefixedString("abc"),
            PrefixedString("de"),
        ])
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 8)

        var reader = DataReader(writer.data)
        let restored = try MDRArray<PrefixedString>.read(from: &reader)
        #expect(restored.count == 2)
        #expect(restored.value[0].value == "abc")
        #expect(restored.value[1].value == "de")
    }
}

// MARK: - MDRFixedArray Tests

@Suite("MDRFixedArray")
struct MDRFixedArrayTests {
    @Test func roundtripWithElements() throws {
        let original = MDRFixedArray<PrefixedString>([
            PrefixedString("one"),
            PrefixedString("two"),
            PrefixedString("three"),
        ])
        var writer = DataWriter()
        original.write(to: &writer)
        // No length prefix, just 3 PrefixedStrings: (1+3)+(1+3)+(1+5) = 14
        #expect(writer.data.count == 14)

        var reader = DataReader(writer.data)
        let restored = try MDRFixedArray<PrefixedString>.read(from: &reader, count: 3)
        #expect(restored.value == original.value)
        #expect(restored.fixedCount == 3)
    }

    @Test func emptyArray() throws {
        let original = MDRFixedArray<PrefixedString>([])
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 0) // No length prefix, no elements

        var reader = DataReader(writer.data)
        let restored = try MDRFixedArray<PrefixedString>.read(from: &reader, count: 0)
        #expect(restored.value.isEmpty)
        #expect(restored.fixedCount == 0)
    }

    @Test func initWithDefaultValue() {
        let arr = MDRFixedArray<PrefixedString>(count: 2, defaultValue: PrefixedString("x"))
        #expect(arr.fixedCount == 2)
        #expect(arr.value.count == 2)
        #expect(arr.value[0].value == "x")
        #expect(arr.value[1].value == "x")
    }
}

// MARK: - PodArray Multi-byte Tests

@Suite("PodArray Multi-byte")
struct PodArrayMultiByteTests {
    @Test func uint16Roundtrip() throws {
        let original = PodArray<UInt16>([0x1234, 0xABCD, 0x0001])
        var writer = DataWriter()
        original.write(to: &writer)
        // count(1) + 3*2 = 7
        #expect(writer.data.count == 7)

        var reader = DataReader(writer.data)
        let restored = try PodArray<UInt16>.read(from: &reader)
        #expect(restored.value == [0x1234, 0xABCD, 0x0001])
    }

    @Test func uint32Roundtrip() throws {
        let original = PodArray<UInt32>([0x12345678, 0xDEADBEEF])
        var writer = DataWriter()
        original.write(to: &writer)
        // count(1) + 2*4 = 9
        #expect(writer.data.count == 9)

        var reader = DataReader(writer.data)
        let restored = try PodArray<UInt32>.read(from: &reader)
        #expect(restored.value == [0x12345678, 0xDEADBEEF])
    }
}

// MARK: - BigEndian Setter Tests

@Suite("BigEndian Setters")
struct BigEndianSetterTests {
    @Test func int16BESetter() {
        var v = Int16BE(0)
        v.value = 0x0102
        #expect(v.value == 0x0102)
        #expect(v.byte0 == 0x01)
        #expect(v.byte1 == 0x02)
    }

    @Test func int16BESetterNegative() {
        var v = Int16BE(0)
        v.value = -1
        #expect(v.value == -1)
        #expect(v.byte0 == 0xFF)
        #expect(v.byte1 == 0xFF)
    }

    @Test func int24BESetter() {
        var v = Int24BE()
        v.value = 42
        // Setter replicates C++ bug: low = 42 & 0xFF = 42, mid = (42>>8) & 0xFF = 0, high = 42 & 0xFF = 42
        #expect(v.byte0 == 42)
        #expect(v.byte1 == 0)
        #expect(v.byte2 == 42)
        // Value read back: 42 << 16 | 0 << 8 | 42 = 0x2A002A
        #expect(v.value == Int32(42) << 16 | Int32(42))
    }

    @Test func int32BESetterBytes() {
        var v = Int32BE()
        v.value = 0x01020304
        #expect(v.byte0 == 0x01)
        #expect(v.byte1 == 0x02)
        #expect(v.byte2 == 0x03)
        #expect(v.byte3 == 0x04)
    }
}
