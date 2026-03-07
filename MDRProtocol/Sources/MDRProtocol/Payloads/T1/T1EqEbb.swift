import Foundation

// MARK: - EqEbb payload structs (from ProtocolV2T1.hpp)

public struct EqEbbGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_GET_STATUS
    public var type: EqEbbInquiredType

    public init(command: T1Command = .EQEBB_GET_STATUS, type: EqEbbInquiredType = .PRESET_EQ) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .PRESET_EQ
        return Self(command: command, type: type)
    }
}

public struct EqEbbGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_GET_PARAM
    public var type: EqEbbInquiredType

    public init(command: T1Command = .EQEBB_GET_PARAM, type: EqEbbInquiredType = .PRESET_EQ) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .PRESET_EQ
        return Self(command: command, type: type)
    }
}

public struct EqEbbStatusOnOff: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_RET_STATUS
    public var type: EqEbbInquiredType
    public var status: MessageMdrV2OnOffSettingValue

    public init(
        command: T1Command = .EQEBB_RET_STATUS,
        type: EqEbbInquiredType = .PRESET_EQ,
        status: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.status = status
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(status.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .PRESET_EQ
        let status = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, status: status)
    }
}

public struct EqEbbStatusErrorCode: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_RET_STATUS
    public var type: EqEbbInquiredType = .PRESET_EQ_AND_ERRORCODE
    public var value: MessageMdrV2EnableDisable
    public var errors: PodArray<UInt8>

    public init(
        command: T1Command = .EQEBB_RET_STATUS,
        type: EqEbbInquiredType = .PRESET_EQ_AND_ERRORCODE,
        value: MessageMdrV2EnableDisable = .DISABLE,
        errors: PodArray<UInt8> = PodArray()
    ) {
        self.command = command
        self.type = type
        self.value = value
        self.errors = errors
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(value.rawValue)
        errors.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .PRESET_EQ_AND_ERRORCODE
        let value = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let errors = try PodArray<UInt8>.read(from: &reader)
        return Self(command: command, type: type, value: value, errors: errors)
    }
}

public struct EqEbbParamEq: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_SET_PARAM
    public var type: EqEbbInquiredType = .PRESET_EQ
    public var presetId: EqPresetId
    public var bands: PodArray<UInt8>

    public init(
        command: T1Command = .EQEBB_SET_PARAM,
        type: EqEbbInquiredType = .PRESET_EQ,
        presetId: EqPresetId = .OFF,
        bands: PodArray<UInt8> = PodArray()
    ) {
        self.command = command
        self.type = type
        self.presetId = presetId
        self.bands = bands
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(presetId.rawValue)
        bands.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .PRESET_EQ
        let presetId = EqPresetId(rawValue: try reader.readUInt8()) ?? .OFF
        let bands = try PodArray<UInt8>.read(from: &reader)
        return Self(command: command, type: type, presetId: presetId, bands: bands)
    }
}

public struct EqEbbParamEbb: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_RET_PARAM
    public var type: EqEbbInquiredType = .EBB
    public var level: UInt8

    public init(
        command: T1Command = .EQEBB_RET_PARAM,
        type: EqEbbInquiredType = .EBB,
        level: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.level = level
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(level)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .EBB
        let level = try reader.readUInt8()
        return Self(command: command, type: type, level: level)
    }
}

public struct EqEbbParamEqAndUltMode: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_RET_PARAM
    public var type: EqEbbInquiredType = .PRESET_EQ_AND_ULT_MODE
    public var presetId: EqPresetId
    public var eqUltModeStatus: EqUltMode
    public var bandSteps: PodArray<UInt8>

    public init(
        command: T1Command = .EQEBB_RET_PARAM,
        type: EqEbbInquiredType = .PRESET_EQ_AND_ULT_MODE,
        presetId: EqPresetId = .OFF,
        eqUltModeStatus: EqUltMode = .OFF,
        bandSteps: PodArray<UInt8> = PodArray()
    ) {
        self.command = command
        self.type = type
        self.presetId = presetId
        self.eqUltModeStatus = eqUltModeStatus
        self.bandSteps = bandSteps
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(presetId.rawValue)
        writer.writeUInt8(eqUltModeStatus.rawValue)
        bandSteps.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .PRESET_EQ_AND_ULT_MODE
        let presetId = EqPresetId(rawValue: try reader.readUInt8()) ?? .OFF
        let eqUltModeStatus = EqUltMode(rawValue: try reader.readUInt8()) ?? .OFF
        let bandSteps = try PodArray<UInt8>.read(from: &reader)
        return Self(command: command, type: type, presetId: presetId, eqUltModeStatus: eqUltModeStatus, bandSteps: bandSteps)
    }
}

public struct EqEbbParamSoundEffect: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_RET_PARAM
    public var type: EqEbbInquiredType = .SOUND_EFFECT
    public var soundEffectValue: SoundEffectType

    public init(
        command: T1Command = .EQEBB_RET_PARAM,
        type: EqEbbInquiredType = .SOUND_EFFECT,
        soundEffectValue: SoundEffectType = .SOUND_EFFECT_OFF
    ) {
        self.command = command
        self.type = type
        self.soundEffectValue = soundEffectValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(soundEffectValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .SOUND_EFFECT
        let soundEffectValue = SoundEffectType(rawValue: try reader.readUInt8()) ?? .SOUND_EFFECT_OFF
        return Self(command: command, type: type, soundEffectValue: soundEffectValue)
    }
}

public struct EqEbbParamCustomEq: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .EQEBB_RET_PARAM
    public var type: EqEbbInquiredType = .CUSTOM_EQ
    public var bandSteps: PodArray<UInt8>

    public init(
        command: T1Command = .EQEBB_RET_PARAM,
        type: EqEbbInquiredType = .CUSTOM_EQ,
        bandSteps: PodArray<UInt8> = PodArray()
    ) {
        self.command = command
        self.type = type
        self.bandSteps = bandSteps
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        bandSteps.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = EqEbbInquiredType(rawValue: try reader.readUInt8()) ?? .CUSTOM_EQ
        let bandSteps = try PodArray<UInt8>.read(from: &reader)
        return Self(command: command, type: type, bandSteps: bandSteps)
    }
}
