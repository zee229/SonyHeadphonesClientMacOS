import Foundation

// MARK: - T2 Connect payloads from ProtocolV2T2.hpp

// MARK: T2ConnectGetSupportFunction

public struct T2ConnectGetSupportFunction: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .CONNECT_GET_SUPPORT_FUNCTION
    public var inquiredType: T2ConnectInquiredType = .FIXED_VALUE

    public init(
        command: T2Command = .CONNECT_GET_SUPPORT_FUNCTION,
        inquiredType: T2ConnectInquiredType = .FIXED_VALUE
    ) {
        self.command = command
        self.inquiredType = inquiredType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = T2ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        return Self(command: command, inquiredType: inquiredType)
    }
}

// MARK: T2ConnectRetSupportFunction (EXTERN)

public struct T2ConnectRetSupportFunction: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .CONNECT_RET_SUPPORT_FUNCTION
    public var inquiredType: T2ConnectInquiredType = .FIXED_VALUE
    public var supportFunctions: [SupportFunctionEntry] = []

    public init(
        command: T2Command = .CONNECT_RET_SUPPORT_FUNCTION,
        inquiredType: T2ConnectInquiredType = .FIXED_VALUE,
        supportFunctions: [SupportFunctionEntry] = []
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.supportFunctions = supportFunctions
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        precondition(supportFunctions.count <= 255, "SupportFunctions array too long")
        writer.writeUInt8(UInt8(supportFunctions.count))
        for entry in supportFunctions {
            entry.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = T2ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        let count = try reader.readUInt8()
        var supportFunctions: [SupportFunctionEntry] = []
        supportFunctions.reserveCapacity(Int(count))
        for _ in 0..<count {
            let entry = try SupportFunctionEntry.read(from: &reader)
            supportFunctions.append(entry)
        }
        return Self(
            command: command,
            inquiredType: inquiredType,
            supportFunctions: supportFunctions
        )
    }
}
