import Foundation

/// Escape special bytes (60, 61, 62) in MDR protocol data.
/// Matches C++ `Escape()` from Command.cpp.
public func mdrEscape(_ data: Data) -> Data {
    var result = Data()
    result.reserveCapacity(data.count * 2)
    for byte in data {
        switch byte {
        case 60:
            result.append(kEscapedByteSentry)
            result.append(kEscaped60)
        case 61:
            result.append(kEscapedByteSentry)
            result.append(kEscaped61)
        case 62:
            result.append(kEscapedByteSentry)
            result.append(kEscaped62)
        default:
            result.append(byte)
        }
    }
    return result
}

/// Unescape MDR protocol data. Returns nil if escape sequence is invalid.
/// Matches C++ `Unescape()` from Command.cpp.
public func mdrUnescape(_ data: Data) -> Data? {
    var result = Data()
    result.reserveCapacity(data.count)
    var i = data.startIndex
    while i < data.endIndex {
        let byte = data[i]
        i += 1
        if byte == kEscapedByteSentry {
            guard i < data.endIndex else { return nil }
            switch data[i] {
            case kEscaped60: result.append(60)
            case kEscaped61: result.append(61)
            case kEscaped62: result.append(62)
            default: return nil
            }
            i += 1
        } else {
            result.append(byte)
        }
    }
    return result
}
