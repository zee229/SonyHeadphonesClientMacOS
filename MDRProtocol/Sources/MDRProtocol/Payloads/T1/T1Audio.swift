import Foundation

// MARK: - Audio payload structs (from ProtocolV2T1.hpp)

// MARK: AudioGetCapability

public struct AudioGetCapability: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_GET_CAPABILITY
    public var type: AudioInquiredType

    public init(
        command: T1Command = .AUDIO_GET_CAPABILITY,
        type: AudioInquiredType = .CONNECTION_MODE
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
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE
        return Self(command: command, type: type)
    }
}

// MARK: AudioRetCapabilityUpscaling

public struct AudioRetCapabilityUpscaling: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_CAPABILITY
    public var type: AudioInquiredType = .UPSCALING
    public var upscalingType: UpscalingType

    public init(
        command: T1Command = .AUDIO_RET_CAPABILITY,
        type: AudioInquiredType = .UPSCALING,
        upscalingType: UpscalingType = .DSEE_HX
    ) {
        self.command = command
        self.type = type
        self.upscalingType = upscalingType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(upscalingType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .UPSCALING
        let upscalingType = UpscalingType(rawValue: try reader.readUInt8()) ?? .DSEE_HX
        return Self(command: command, type: type, upscalingType: upscalingType)
    }
}

// MARK: AudioGetStatus

public struct AudioGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_GET_STATUS
    public var type: AudioInquiredType

    public init(
        command: T1Command = .AUDIO_GET_STATUS,
        type: AudioInquiredType = .CONNECTION_MODE
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
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE
        return Self(command: command, type: type)
    }
}

// MARK: AudioGetParam

public struct AudioGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_GET_PARAM
    public var type: AudioInquiredType

    public init(
        command: T1Command = .AUDIO_GET_PARAM,
        type: AudioInquiredType = .CONNECTION_MODE
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
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE
        return Self(command: command, type: type)
    }
}

// MARK: AudioParamConnection

public struct AudioParamConnection: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .CONNECTION_MODE
    public var settingValue: PriorMode

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .CONNECTION_MODE,
        settingValue: PriorMode = .SOUND_QUALITY_PRIOR
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
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE
        let settingValue = PriorMode(rawValue: try reader.readUInt8()) ?? .SOUND_QUALITY_PRIOR
        return Self(command: command, type: type, settingValue: settingValue)
    }
}

// MARK: AudioParamUpscaling

public struct AudioParamUpscaling: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .UPSCALING
    public var settingValue: UpscalingTypeAutoOff

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .UPSCALING,
        settingValue: UpscalingTypeAutoOff = .OFF
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
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .UPSCALING
        let settingValue = UpscalingTypeAutoOff(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, settingValue: settingValue)
    }
}

// MARK: AudioStatusCommon

public struct AudioStatusCommon: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_STATUS
    public var type: AudioInquiredType = .CONNECTION_MODE
    public var status: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .AUDIO_RET_STATUS,
        type: AudioInquiredType = .CONNECTION_MODE,
        status: MessageMdrV2EnableDisable = .DISABLE
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
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, status: status)
    }
}

// MARK: AudioParamConnectionWithLdacStatus

public struct AudioParamConnectionWithLdacStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .CONNECTION_MODE_WITH_LDAC_STATUS
    public var settingValue: PriorMode

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .CONNECTION_MODE_WITH_LDAC_STATUS,
        settingValue: PriorMode = .SOUND_QUALITY_PRIOR
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
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE_WITH_LDAC_STATUS
        let settingValue = PriorMode(rawValue: try reader.readUInt8()) ?? .SOUND_QUALITY_PRIOR
        return Self(command: command, type: type, settingValue: settingValue)
    }
}

// MARK: AudioRetParamConnectionModeClassicAudioLeAudio

public struct AudioRetParamConnectionModeClassicAudioLeAudio: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO
    public var settingValue: PriorMode

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO,
        settingValue: PriorMode = .SOUND_QUALITY_PRIOR
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
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO
        let settingValue = PriorMode(rawValue: try reader.readUInt8()) ?? .SOUND_QUALITY_PRIOR
        return Self(command: command, type: type, settingValue: settingValue)
    }
}

// MARK: AudioParamBGMMode

public struct AudioParamBGMMode: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .BGM_MODE
    public var onOffSettingValue: MessageMdrV2EnableDisable
    public var targetRoomSize: RoomSize

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .BGM_MODE,
        onOffSettingValue: MessageMdrV2EnableDisable = .DISABLE,
        targetRoomSize: RoomSize = .SMALL
    ) {
        self.command = command
        self.type = type
        self.onOffSettingValue = onOffSettingValue
        self.targetRoomSize = targetRoomSize
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(onOffSettingValue.rawValue)
        writer.writeUInt8(targetRoomSize.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .BGM_MODE
        let onOffSettingValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let targetRoomSize = RoomSize(rawValue: try reader.readUInt8()) ?? .SMALL
        return Self(command: command, type: type, onOffSettingValue: onOffSettingValue, targetRoomSize: targetRoomSize)
    }
}

// MARK: AudioParamUpmixCinema

public struct AudioParamUpmixCinema: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .UPMIX_CINEMA
    public var onOffSettingValue: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .UPMIX_CINEMA,
        onOffSettingValue: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.onOffSettingValue = onOffSettingValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(onOffSettingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .UPMIX_CINEMA
        let onOffSettingValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, onOffSettingValue: onOffSettingValue)
    }
}

// MARK: AudioParamVoiceContents

public struct AudioParamVoiceContents: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .VOICE_CONTENTS
    public var onOffSettingValue: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .VOICE_CONTENTS,
        onOffSettingValue: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.onOffSettingValue = onOffSettingValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(onOffSettingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .VOICE_CONTENTS
        let onOffSettingValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, onOffSettingValue: onOffSettingValue)
    }
}

// MARK: AudioParamSoundLeakageReduction

public struct AudioParamSoundLeakageReduction: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .SOUND_LEAKAGE_REDUCTION
    public var onOffSettingValue: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .SOUND_LEAKAGE_REDUCTION,
        onOffSettingValue: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.onOffSettingValue = onOffSettingValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(onOffSettingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .SOUND_LEAKAGE_REDUCTION
        let onOffSettingValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, onOffSettingValue: onOffSettingValue)
    }
}

// MARK: AudioParamListeningOptionAssignCustomizableItem (EXTERN)

public struct AudioParamListeningOptionAssignCustomizableItem: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .LISTENING_OPTION_ASSIGN_CUSTOMIZABLE
    public var items: PodArray<UInt8>

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .LISTENING_OPTION_ASSIGN_CUSTOMIZABLE,
        items: PodArray<UInt8> = PodArray()
    ) {
        self.command = command
        self.type = type
        self.items = items
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        items.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .LISTENING_OPTION_ASSIGN_CUSTOMIZABLE
        let items = try PodArray<UInt8>.read(from: &reader)
        return Self(command: command, type: type, items: items)
    }
}

// MARK: AudioParamUpmixSeries

public struct AudioParamUpmixSeries: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_RET_PARAM
    public var type: AudioInquiredType = .UPMIX_SERIES
    public var upmixItemId: UpmixItemId

    public init(
        command: T1Command = .AUDIO_RET_PARAM,
        type: AudioInquiredType = .UPMIX_SERIES,
        upmixItemId: UpmixItemId = .NONE
    ) {
        self.command = command
        self.type = type
        self.upmixItemId = upmixItemId
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(upmixItemId.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .UPMIX_SERIES
        let upmixItemId = UpmixItemId(rawValue: try reader.readUInt8()) ?? .NONE
        return Self(command: command, type: type, upmixItemId: upmixItemId)
    }
}

// MARK: AudioSetParamConnectionModeClassicAudioLeAudio

public struct AudioSetParamConnectionModeClassicAudioLeAudio: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_SET_PARAM
    public var type: AudioInquiredType = .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO
    public var settingValue: PriorMode
    public var alertConfirmation: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .AUDIO_SET_PARAM,
        type: AudioInquiredType = .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO,
        settingValue: PriorMode = .SOUND_QUALITY_PRIOR,
        alertConfirmation: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.settingValue = settingValue
        self.alertConfirmation = alertConfirmation
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingValue.rawValue)
        writer.writeUInt8(alertConfirmation.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO
        let settingValue = PriorMode(rawValue: try reader.readUInt8()) ?? .SOUND_QUALITY_PRIOR
        let alertConfirmation = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, settingValue: settingValue, alertConfirmation: alertConfirmation)
    }
}

// MARK: AudioNtfyParamConnectionModeClassicAudioLeAudio

public struct AudioNtfyParamConnectionModeClassicAudioLeAudio: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .AUDIO_NTFY_PARAM
    public var type: AudioInquiredType = .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO
    public var settingValue: PriorMode
    public var switchingStream: SwitchingStream

    public init(
        command: T1Command = .AUDIO_NTFY_PARAM,
        type: AudioInquiredType = .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO,
        settingValue: PriorMode = .SOUND_QUALITY_PRIOR,
        switchingStream: SwitchingStream = .NONE
    ) {
        self.command = command
        self.type = type
        self.settingValue = settingValue
        self.switchingStream = switchingStream
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingValue.rawValue)
        writer.writeUInt8(switchingStream.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AudioInquiredType(rawValue: try reader.readUInt8()) ?? .CONNECTION_MODE_CLASSIC_AUDIO_LE_AUDIO
        let settingValue = PriorMode(rawValue: try reader.readUInt8()) ?? .SOUND_QUALITY_PRIOR
        let switchingStream = SwitchingStream(rawValue: try reader.readUInt8()) ?? .NONE
        return Self(command: command, type: type, settingValue: settingValue, switchingStream: switchingStream)
    }
}
