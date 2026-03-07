import Foundation

/// Compute MDR checksum (simple sum of all bytes, truncated to UInt8).
/// Matches C++ `Checksum()` from Command.cpp.
public func mdrChecksum(_ data: Data) -> UInt8 {
    var sum: UInt8 = 0
    for byte in data {
        sum &+= byte
    }
    return sum
}

/// Pack a command into an MDR protocol packet.
/// Format: `<START> ESCAPE(type + seq + Int32BE(size) + payload + checksum) <END>`
/// Matches C++ `MDRPackCommand()` from Command.cpp.
public func mdrPackCommand(type: MDRDataType, seq: UInt8, payload: Data) -> Data {
    // Build unescaped content: type + seq + Int32BE(size) + payload
    var unescaped = Data()
    unescaped.reserveCapacity(payload.count + 7)
    unescaped.append(type.rawValue)
    unescaped.append(seq)
    // Int32BE size of payload
    let size = Int32BE(Int32(payload.count))
    unescaped.append(size.byte0)
    unescaped.append(size.byte1)
    unescaped.append(size.byte2)
    unescaped.append(size.byte3)
    unescaped.append(payload)
    // Append checksum
    unescaped.append(mdrChecksum(unescaped))

    // Escape and wrap with markers
    var result = Data()
    result.append(kStartMarker)
    result.append(mdrEscape(unescaped))
    result.append(kEndMarker)
    return result
}

/// Unpack result containing the parsed data, type, and sequence number.
public struct MDRUnpackedCommand: Sendable {
    public let data: Data
    public let type: MDRDataType
    public let seq: UInt8
}

/// Unpack an MDR protocol packet.
/// Returns `.ok` with parsed result, or an error status.
/// Matches C++ `MDRUnpackCommand()` from Command.cpp.
public func mdrUnpackCommand(_ command: Data) -> (MDRUnpackResult, MDRUnpackedCommand?) {
    guard command.count >= 2 else {
        return (.incomplete, nil)
    }
    guard command[command.startIndex] == kStartMarker,
          command[command.endIndex - 1] == kEndMarker else {
        return (.badMarker, nil)
    }

    // Strip markers
    let inner = command[(command.startIndex + 1)..<(command.endIndex - 1)]
    guard let unescaped = mdrUnescape(Data(inner)) else {
        return (.incomplete, nil)
    }

    guard unescaped.count >= 7 else { // type(1) + seq(1) + size(4) + checksum(1)
        return (.incomplete, nil)
    }

    // Parse type and seq
    let rawType = unescaped[0]
    let seq = unescaped[1]
    let type = MDRDataType(rawValue: rawType) ?? .unknown

    // Parse Int32BE size
    let expectedSize = Int(UInt32(unescaped[2]) << 24 |
                          UInt32(unescaped[3]) << 16 |
                          UInt32(unescaped[4]) << 8 |
                          UInt32(unescaped[5]))

    // Verify checksum (over everything except the last byte)
    let checksumData = unescaped[0..<(unescaped.count - 1)]
    let expectedChecksum = unescaped[unescaped.count - 1]
    let actualChecksum = mdrChecksum(Data(checksumData))
    guard expectedChecksum == actualChecksum else {
        return (.badChecksum, nil)
    }

    // Extract data (after type+seq+size, before checksum)
    let dataStart = 6
    let dataEnd = unescaped.count - 1
    let data = Data(unescaped[dataStart..<dataEnd])

    guard data.count == expectedSize else {
        return (.incomplete, nil)
    }

    return (.ok, MDRUnpackedCommand(data: data, type: type, seq: seq))
}
