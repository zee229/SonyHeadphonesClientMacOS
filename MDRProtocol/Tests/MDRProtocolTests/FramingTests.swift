import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Escape Tests

@Suite("Escape")
struct EscapeTests {
    @Test func passThroughNormalBytes() {
        let input = Data([0x00, 0x01, 0x42, 0xFF])
        let escaped = mdrEscape(input)
        #expect(escaped == input)
    }

    @Test func escape60() {
        let input = Data([60])
        let escaped = mdrEscape(input)
        #expect(escaped == Data([kEscapedByteSentry, kEscaped60]))
    }

    @Test func escape61() {
        let input = Data([61])
        let escaped = mdrEscape(input)
        #expect(escaped == Data([kEscapedByteSentry, kEscaped61]))
    }

    @Test func escape62() {
        let input = Data([62])
        let escaped = mdrEscape(input)
        #expect(escaped == Data([kEscapedByteSentry, kEscaped62]))
    }

    @Test func escapeAllSpecialBytes() {
        let input = Data([60, 61, 62])
        let escaped = mdrEscape(input)
        #expect(escaped == Data([
            kEscapedByteSentry, kEscaped60,
            kEscapedByteSentry, kEscaped61,
            kEscapedByteSentry, kEscaped62,
        ]))
        #expect(escaped.count == 6)
    }

    @Test func escapeEmptyInput() {
        #expect(mdrEscape(Data()).isEmpty)
    }

    @Test func escapeMixedBytes() {
        let input = Data([0x01, 60, 0x02, 62, 0x03])
        let escaped = mdrEscape(input)
        #expect(escaped == Data([
            0x01,
            kEscapedByteSentry, kEscaped60,
            0x02,
            kEscapedByteSentry, kEscaped62,
            0x03,
        ]))
    }
}

// MARK: - Unescape Tests

@Suite("Unescape")
struct UnescapeTests {
    @Test func unescapeRoundtrip() {
        let original = Data([0x01, 60, 61, 62, 0xFF])
        let escaped = mdrEscape(original)
        let unescaped = mdrUnescape(escaped)
        #expect(unescaped == original)
    }

    @Test func unescapeEmptyInput() {
        #expect(mdrUnescape(Data()) == Data())
    }

    @Test func unescapeNormalBytes() {
        let input = Data([0x01, 0x42, 0xFF])
        #expect(mdrUnescape(input) == input)
    }

    @Test func unescapeTruncatedSequenceReturnsNil() {
        // Ends with sentry but no following byte
        let input = Data([0x01, kEscapedByteSentry])
        #expect(mdrUnescape(input) == nil)
    }

    @Test func unescapeInvalidEscapeReturnsNil() {
        // Sentry followed by invalid escape byte
        let input = Data([kEscapedByteSentry, 0x99])
        #expect(mdrUnescape(input) == nil)
    }

    @Test func unescapeAllThreeSpecials() {
        let input = Data([
            kEscapedByteSentry, kEscaped60,
            kEscapedByteSentry, kEscaped61,
            kEscapedByteSentry, kEscaped62,
        ])
        #expect(mdrUnescape(input) == Data([60, 61, 62]))
    }
}

// MARK: - Checksum Tests

@Suite("Checksum")
struct ChecksumTests {
    @Test func emptyDataChecksum() {
        #expect(mdrChecksum(Data()) == 0)
    }

    @Test func singleByteChecksum() {
        #expect(mdrChecksum(Data([0x42])) == 0x42)
    }

    @Test func multiByteChecksum() {
        // 1 + 2 + 3 = 6
        #expect(mdrChecksum(Data([1, 2, 3])) == 6)
    }

    @Test func checksumWraps() {
        // 0xFF + 0x01 = 0x00 (wraps)
        #expect(mdrChecksum(Data([0xFF, 0x01])) == 0x00)
    }

    @Test func checksumWraps2() {
        // 0xFF + 0x02 = 0x01
        #expect(mdrChecksum(Data([0xFF, 0x02])) == 0x01)
    }
}

// MARK: - Pack/Unpack Tests

@Suite("PackUnpack")
struct PackUnpackTests {
    @Test func packEmptyPayload() {
        let packed = mdrPackCommand(type: .dataMdr, seq: 0, payload: Data())
        // Should start with start marker and end with end marker
        #expect(packed.first == kStartMarker)
        #expect(packed.last == kEndMarker)
    }

    @Test func packUnpackRoundtrip() {
        let payload = Data([0x01, 0x02, 0x03])
        let packed = mdrPackCommand(type: .dataMdr, seq: 42, payload: payload)
        let (result, unpacked) = mdrUnpackCommand(packed)
        #expect(result == .ok)
        #expect(unpacked?.type == .dataMdr)
        #expect(unpacked?.seq == 42)
        #expect(unpacked?.data == payload)
    }

    @Test func packUnpackEmptyPayload() {
        let packed = mdrPackCommand(type: .ack, seq: 0, payload: Data())
        let (result, unpacked) = mdrUnpackCommand(packed)
        #expect(result == .ok)
        #expect(unpacked?.type == .ack)
        #expect(unpacked?.seq == 0)
        #expect(unpacked?.data == Data())
    }

    @Test func packUnpackWithSpecialBytes() {
        // Payload containing bytes that need escaping
        let payload = Data([60, 61, 62])
        let packed = mdrPackCommand(type: .dataMdr, seq: 1, payload: payload)
        let (result, unpacked) = mdrUnpackCommand(packed)
        #expect(result == .ok)
        #expect(unpacked?.data == payload)
    }

    @Test func packUnpackLargePayload() {
        let payload = Data(repeating: 0xAA, count: 256)
        let packed = mdrPackCommand(type: .dataMdr, seq: 99, payload: payload)
        let (result, unpacked) = mdrUnpackCommand(packed)
        #expect(result == .ok)
        #expect(unpacked?.data == payload)
        #expect(unpacked?.seq == 99)
    }

    @Test func unpackIncompleteEmpty() {
        let (result, _) = mdrUnpackCommand(Data())
        #expect(result == .incomplete)
    }

    @Test func unpackIncompleteOneByte() {
        let (result, _) = mdrUnpackCommand(Data([kStartMarker]))
        #expect(result == .incomplete)
    }

    @Test func unpackBadMarkerNoStart() {
        let (result, _) = mdrUnpackCommand(Data([0x01, kEndMarker]))
        #expect(result == .badMarker)
    }

    @Test func unpackBadMarkerNoEnd() {
        let (result, _) = mdrUnpackCommand(Data([kStartMarker, 0x01]))
        #expect(result == .badMarker)
    }

    @Test func unpackBadChecksum() {
        var packed = mdrPackCommand(type: .dataMdr, seq: 0, payload: Data([0x42]))
        // Corrupt a byte before the end marker
        packed[packed.count - 2] ^= 0xFF
        let (result, _) = mdrUnpackCommand(packed)
        // Should be badChecksum or incomplete due to corruption
        #expect(result != .ok)
    }

    @Test func packSequenceNumber() {
        for seq: UInt8 in [0, 1, 127, 255] {
            let packed = mdrPackCommand(type: .dataMdr, seq: seq, payload: Data([0x01]))
            let (result, unpacked) = mdrUnpackCommand(packed)
            #expect(result == .ok)
            #expect(unpacked?.seq == seq)
        }
    }

    @Test func packAllDataTypes() {
        let types: [MDRDataType] = [.data, .ack, .dataMdr, .dataMdrNo2, .shotMdr, .dataCommon]
        for type in types {
            let packed = mdrPackCommand(type: type, seq: 0, payload: Data([0x01]))
            let (result, unpacked) = mdrUnpackCommand(packed)
            #expect(result == .ok)
            #expect(unpacked?.type == type)
        }
    }

    @Test func packVerifyByteLayout() {
        // Verify the exact byte layout matches C++ MDRPackCommand
        let packed = mdrPackCommand(type: .dataMdr, seq: 0, payload: Data())
        // Expected unescaped: [0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, checksum]
        // type=12(0x0C), seq=0, size=Int32BE(0), checksum=0x0C
        // After escape: none of these bytes need escaping
        // Final: [62, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 60]
        #expect(packed == Data([62, 0x0C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 60]))
    }
}
