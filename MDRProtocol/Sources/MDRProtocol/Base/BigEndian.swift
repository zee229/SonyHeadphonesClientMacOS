import Foundation

/// 16-bit big-endian integer stored as 2 bytes.
/// Matches C++ `Int16BE` from Protocol.hpp.
public struct Int16BE: Sendable {
    public var byte0: UInt8 // MSB
    public var byte1: UInt8 // LSB

    public init() {
        byte0 = 0
        byte1 = 0
    }

    public init(_ value: Int16) {
        let v = UInt16(bitPattern: value)
        byte0 = UInt8(v >> 8)
        byte1 = UInt8(v & 0xFF)
    }

    public var value: Int16 {
        get {
            Int16(bitPattern: UInt16(byte0) << 8 | UInt16(byte1))
        }
        set {
            let v = UInt16(bitPattern: newValue)
            byte0 = UInt8(v >> 8)
            byte1 = UInt8(v & 0xFF)
        }
    }
}

extension Int16BE: Equatable {
    public static func == (lhs: Int16BE, rhs: Int16BE) -> Bool {
        lhs.byte0 == rhs.byte0 && lhs.byte1 == rhs.byte1
    }
}

/// 24-bit big-endian integer stored as 3 bytes.
/// Matches C++ `Int24BE` from Protocol.hpp.
///
/// Note: The C++ implementation has a bug in the assignment operator where
/// `high` gets the same value as `low` (`high = v & 0xFF` instead of `high = (v >> 16) & 0xFF`).
/// We replicate this bug for byte-level compatibility.
public struct Int24BE: Sendable {
    public var byte0: UInt8 // low in C++ struct layout
    public var byte1: UInt8 // mid
    public var byte2: UInt8 // high

    public init() {
        byte0 = 0
        byte1 = 0
        byte2 = 0
    }

    /// Initialize matching C++ behavior (which has a bug: high = v & 0xFF instead of (v >> 16) & 0xFF)
    public init(_ value: Int32) {
        // C++ stores: low = v & 0xFF, mid = (v >> 8) & 0xFF, high = v & 0xFF (bug!)
        // C++ reads:  low << 16 | mid << 8 | high
        byte0 = UInt8(value & 0xFF)         // low
        byte1 = UInt8((value >> 8) & 0xFF)   // mid
        byte2 = UInt8(value & 0xFF)           // high (C++ bug replicated)
    }

    /// Read value matching C++ `operator int32_t()`: `low << 16 | mid << 8 | high`
    public var value: Int32 {
        get {
            Int32(byte0) << 16 | Int32(byte1) << 8 | Int32(byte2)
        }
        set {
            byte0 = UInt8(newValue & 0xFF)         // low
            byte1 = UInt8((newValue >> 8) & 0xFF)   // mid
            byte2 = UInt8(newValue & 0xFF)           // high (C++ bug replicated)
        }
    }
}

extension Int24BE: Equatable {
    public static func == (lhs: Int24BE, rhs: Int24BE) -> Bool {
        lhs.byte0 == rhs.byte0 && lhs.byte1 == rhs.byte1 && lhs.byte2 == rhs.byte2
    }
}

/// 32-bit big-endian integer stored as 4 bytes.
/// Matches C++ `Int32BE` from Protocol.hpp.
public struct Int32BE: Sendable {
    public var byte0: UInt8 // MSB
    public var byte1: UInt8
    public var byte2: UInt8
    public var byte3: UInt8 // LSB

    public init() {
        byte0 = 0
        byte1 = 0
        byte2 = 0
        byte3 = 0
    }

    public init(_ value: Int32) {
        let v = UInt32(bitPattern: value)
        byte0 = UInt8((v >> 24) & 0xFF)
        byte1 = UInt8((v >> 16) & 0xFF)
        byte2 = UInt8((v >> 8) & 0xFF)
        byte3 = UInt8(v & 0xFF)
    }

    public var value: Int32 {
        get {
            Int32(bitPattern:
                UInt32(byte0) << 24 |
                UInt32(byte1) << 16 |
                UInt32(byte2) << 8 |
                UInt32(byte3)
            )
        }
        set {
            let v = UInt32(bitPattern: newValue)
            byte0 = UInt8((v >> 24) & 0xFF)
            byte1 = UInt8((v >> 16) & 0xFF)
            byte2 = UInt8((v >> 8) & 0xFF)
            byte3 = UInt8(v & 0xFF)
        }
    }
}

extension Int32BE: Equatable {
    public static func == (lhs: Int32BE, rhs: Int32BE) -> Bool {
        lhs.byte0 == rhs.byte0 && lhs.byte1 == rhs.byte1 &&
        lhs.byte2 == rhs.byte2 && lhs.byte3 == rhs.byte3
    }
}
