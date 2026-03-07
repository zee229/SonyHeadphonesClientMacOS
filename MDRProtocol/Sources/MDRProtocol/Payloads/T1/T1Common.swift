import Foundation

// MARK: - Common payload structs (from ProtocolV2T1.hpp)

// MARK: CommonGetStatus

public struct CommonGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .COMMON_GET_STATUS
    public var type: CommonInquiredType

    public init(
        command: T1Command = .COMMON_GET_STATUS,
        type: CommonInquiredType = .AUDIO_CODEC
    ) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = CommonInquiredType(rawValue: try reader.readUInt8()) ?? .AUDIO_CODEC
        return Self(command: command, type: type)
    }
}

// MARK: CommonStatusAudioCodec

public struct CommonStatusAudioCodec: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .COMMON_RET_STATUS
    public var type: CommonInquiredType = .AUDIO_CODEC
    public var audioCodec: AudioCodec

    public init(
        command: T1Command = .COMMON_RET_STATUS,
        type: CommonInquiredType = .AUDIO_CODEC,
        audioCodec: AudioCodec = .UNSETTLED
    ) {
        self.command = command
        self.type = type
        self.audioCodec = audioCodec
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(audioCodec.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = CommonInquiredType(rawValue: try reader.readUInt8()) ?? .AUDIO_CODEC
        let audioCodec = AudioCodec(rawValue: try reader.readUInt8()) ?? .UNSETTLED
        return Self(command: command, type: type, audioCodec: audioCodec)
    }
}
