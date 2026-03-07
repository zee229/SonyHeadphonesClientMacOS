import Foundation

// MARK: - T2 VoiceGuidance payloads from ProtocolV2T2.hpp

// MARK: VoiceGuidanceGetParam

public struct VoiceGuidanceGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .VOICE_GUIDANCE_GET_PARAM
    public var type: VoiceGuidanceInquiredType

    public init(
        command: T2Command = .VOICE_GUIDANCE_GET_PARAM,
        type: VoiceGuidanceInquiredType = .MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH
    ) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = VoiceGuidanceInquiredType(rawValue: try reader.readUInt8()) ?? .MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH
        return Self(command: command, type: type)
    }
}

// MARK: VoiceGuidanceParamSettingMtk

public struct VoiceGuidanceParamSettingMtk: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .VOICE_GUIDANCE_RET_PARAM
    public var type: VoiceGuidanceInquiredType = .MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH
    public var settingValue: MessageMdrV2OnOffSettingValue

    public init(
        command: T2Command = .VOICE_GUIDANCE_RET_PARAM,
        type: VoiceGuidanceInquiredType = .MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH,
        settingValue: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.settingValue = settingValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = VoiceGuidanceInquiredType(rawValue: try reader.readUInt8()) ?? .MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH
        let settingValue = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, settingValue: settingValue)
    }
}

// MARK: VoiceGuidanceParamSettingSupportLangSwitch

public struct VoiceGuidanceParamSettingSupportLangSwitch: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .VOICE_GUIDANCE_RET_PARAM
    public var type: VoiceGuidanceInquiredType = .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH
    public var settingValue: MessageMdrV2OnOffSettingValue
    public var languageValue: VoiceGuidanceLanguage

    public init(
        command: T2Command = .VOICE_GUIDANCE_RET_PARAM,
        type: VoiceGuidanceInquiredType = .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH,
        settingValue: MessageMdrV2OnOffSettingValue = .OFF,
        languageValue: VoiceGuidanceLanguage = .UNDEFINED_LANGUAGE
    ) {
        self.command = command
        self.type = type
        self.settingValue = settingValue
        self.languageValue = languageValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingValue.rawValue)
        writer.writeUInt8(languageValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = VoiceGuidanceInquiredType(rawValue: try reader.readUInt8()) ?? .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH
        let settingValue = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        let languageValue = VoiceGuidanceLanguage(rawValue: try reader.readUInt8()) ?? .UNDEFINED_LANGUAGE
        return Self(command: command, type: type, settingValue: settingValue, languageValue: languageValue)
    }
}

// MARK: VoiceGuidanceParamVolume

public struct VoiceGuidanceParamVolume: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .VOICE_GUIDANCE_RET_PARAM
    public var type: VoiceGuidanceInquiredType = .VOLUME
    public var volumeValue: Int8

    public init(
        command: T2Command = .VOICE_GUIDANCE_RET_PARAM,
        type: VoiceGuidanceInquiredType = .VOLUME,
        volumeValue: Int8 = 0
    ) {
        self.command = command
        self.type = type
        self.volumeValue = volumeValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeInt8(volumeValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = VoiceGuidanceInquiredType(rawValue: try reader.readUInt8()) ?? .VOLUME
        let volumeValue = try reader.readInt8()
        return Self(command: command, type: type, volumeValue: volumeValue)
    }
}

// MARK: VoiceGuidanceParamSettingOnOff

public struct VoiceGuidanceParamSettingOnOff: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .VOICE_GUIDANCE_RET_PARAM
    public var type: VoiceGuidanceInquiredType = .ONLY_ON_OFF_SETTING
    public var settingValue: MessageMdrV2OnOffSettingValue

    public init(
        command: T2Command = .VOICE_GUIDANCE_RET_PARAM,
        type: VoiceGuidanceInquiredType = .ONLY_ON_OFF_SETTING,
        settingValue: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.settingValue = settingValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = VoiceGuidanceInquiredType(rawValue: try reader.readUInt8()) ?? .ONLY_ON_OFF_SETTING
        let settingValue = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, settingValue: settingValue)
    }
}

// MARK: VoiceGuidanceSetParamVolume

public struct VoiceGuidanceSetParamVolume: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .VOICE_GUIDANCE_SET_PARAM
    public var type: VoiceGuidanceInquiredType = .VOLUME
    public var volumeValue: Int8
    public var feedbackSound: MessageMdrV2OnOffSettingValue

    public init(
        command: T2Command = .VOICE_GUIDANCE_SET_PARAM,
        type: VoiceGuidanceInquiredType = .VOLUME,
        volumeValue: Int8 = 0,
        feedbackSound: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.volumeValue = volumeValue
        self.feedbackSound = feedbackSound
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeInt8(volumeValue)
        writer.writeUInt8(feedbackSound.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = VoiceGuidanceInquiredType(rawValue: try reader.readUInt8()) ?? .VOLUME
        let volumeValue = try reader.readInt8()
        let feedbackSound = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, volumeValue: volumeValue, feedbackSound: feedbackSound)
    }
}
