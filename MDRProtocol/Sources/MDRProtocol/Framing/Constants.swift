import Foundation

/// MDR protocol framing constants.
/// Matches C++ `Command.hpp`.

public let kStartMarker: UInt8 = 62      // '>'
public let kEndMarker: UInt8 = 60        // '<'
public let kEscapedByteSentry: UInt8 = 0x3D // '='
public let kEscaped60: UInt8 = 44        // 0x3C -> 0x3D 0x2C
public let kEscaped61: UInt8 = 45        // 0x3D -> 0x3D 0x2D
public let kEscaped62: UInt8 = 46        // 0x3E -> 0x3D 0x2E
public let kMDRMaxPacketSize = 2048

/// Data type for MDR commands.
/// Matches C++ `MDRDataType`.
public enum MDRDataType: UInt8, Sendable {
    case data = 0
    case ack = 1
    case dataMcNo1 = 2
    case dataIcd = 9
    case dataEv = 10
    case dataMdr = 12
    case dataCommon = 13
    case dataMdrNo2 = 14
    case shot = 16
    case shotMcNo1 = 18
    case shotIcd = 25
    case shotEv = 26
    case shotMdr = 28
    case shotCommon = 29
    case shotMdrNo2 = 30
    case largeDataCommon = 45
    case unknown = 0xFF
}

/// Result of unpacking an MDR command.
public enum MDRUnpackResult: Sendable {
    case ok
    case incomplete
    case badMarker
    case badChecksum
}
