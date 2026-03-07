import Foundation

// MARK: - Play payload structs (from ProtocolV2T1.hpp)

public struct GetPlayParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_GET_PARAM
    public var type: PlayInquiredType

    public init(command: T1Command = .PLAY_GET_PARAM, type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
        return Self(command: command, type: type)
    }
}

public struct GetPlayStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_GET_STATUS
    public var type: PlayInquiredType

    public init(command: T1Command = .PLAY_GET_STATUS, type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
        return Self(command: command, type: type)
    }
}

public struct PlayStatusPlaybackController: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_RET_STATUS
    public var type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
    public var status: MessageMdrV2EnableDisable
    public var playbackStatus: PlaybackStatus
    public var musicCallStatus: MusicCallStatus

    public init(
        command: T1Command = .PLAY_RET_STATUS,
        type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
        status: MessageMdrV2EnableDisable = .DISABLE,
        playbackStatus: PlaybackStatus = .UNSETTLED,
        musicCallStatus: MusicCallStatus = .MUSIC
    ) {
        self.command = command
        self.type = type
        self.status = status
        self.playbackStatus = playbackStatus
        self.musicCallStatus = musicCallStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(status.rawValue)
        writer.writeUInt8(playbackStatus.rawValue)
        writer.writeUInt8(musicCallStatus.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let playbackStatus = PlaybackStatus(rawValue: try reader.readUInt8()) ?? .UNSETTLED
        let musicCallStatus = MusicCallStatus(rawValue: try reader.readUInt8()) ?? .MUSIC
        return Self(command: command, type: type, status: status, playbackStatus: playbackStatus, musicCallStatus: musicCallStatus)
    }
}

// MARK: PlayStatusPlaybackControlWithCallVolumeAdjustmentAndFunctionChange

public struct PlayStatusPlaybackControlWithCallVolumeAdjustmentAndFunctionChange: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_RET_STATUS
    public var type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT_AND_FUNCTION_CHANGE
    public var status: MessageMdrV2EnableDisable
    public var playbackStatus: PlaybackStatus
    public var musicCallStatus: MusicCallStatus
    public var playbackControlStatus: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .PLAY_RET_STATUS,
        type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT_AND_FUNCTION_CHANGE,
        status: MessageMdrV2EnableDisable = .DISABLE,
        playbackStatus: PlaybackStatus = .UNSETTLED,
        musicCallStatus: MusicCallStatus = .MUSIC,
        playbackControlStatus: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.status = status
        self.playbackStatus = playbackStatus
        self.musicCallStatus = musicCallStatus
        self.playbackControlStatus = playbackControlStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(status.rawValue)
        writer.writeUInt8(playbackStatus.rawValue)
        writer.writeUInt8(musicCallStatus.rawValue)
        writer.writeUInt8(playbackControlStatus.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT_AND_FUNCTION_CHANGE
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let playbackStatus = PlaybackStatus(rawValue: try reader.readUInt8()) ?? .UNSETTLED
        let musicCallStatus = MusicCallStatus(rawValue: try reader.readUInt8()) ?? .MUSIC
        let playbackControlStatus = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(
            command: command,
            type: type,
            status: status,
            playbackStatus: playbackStatus,
            musicCallStatus: musicCallStatus,
            playbackControlStatus: playbackControlStatus
        )
    }
}

// MARK: PlayStatusPlaybackControlWithFunctionChange

public struct PlayStatusPlaybackControlWithFunctionChange: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_RET_STATUS
    public var type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_FUNCTION_CHANGE
    public var status: MessageMdrV2EnableDisable
    public var playbackStatus: PlaybackStatus
    public var playbackControlStatus: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .PLAY_RET_STATUS,
        type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_FUNCTION_CHANGE,
        status: MessageMdrV2EnableDisable = .DISABLE,
        playbackStatus: PlaybackStatus = .UNSETTLED,
        playbackControlStatus: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.status = status
        self.playbackStatus = playbackStatus
        self.playbackControlStatus = playbackControlStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(status.rawValue)
        writer.writeUInt8(playbackStatus.rawValue)
        writer.writeUInt8(playbackControlStatus.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_FUNCTION_CHANGE
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let playbackStatus = PlaybackStatus(rawValue: try reader.readUInt8()) ?? .UNSETTLED
        let playbackControlStatus = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(
            command: command,
            type: type,
            status: status,
            playbackStatus: playbackStatus,
            playbackControlStatus: playbackControlStatus
        )
    }
}

// MARK: PlayStatusCommon

public struct PlayStatusCommon: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_RET_STATUS
    public var type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
    public var status: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .PLAY_RET_STATUS,
        type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
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
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, status: status)
    }
}

// MARK: PlayStatusSetPlaybackController

public struct PlayStatusSetPlaybackController: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_SET_STATUS
    public var type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
    public var status: MessageMdrV2EnableDisable
    public var control: PlaybackControl

    public init(
        command: T1Command = .PLAY_SET_STATUS,
        type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
        status: MessageMdrV2EnableDisable = .DISABLE,
        control: PlaybackControl = .KEY_OFF
    ) {
        self.command = command
        self.type = type
        self.status = status
        self.control = control
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(status.rawValue)
        writer.writeUInt8(control.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let control = PlaybackControl(rawValue: try reader.readUInt8()) ?? .KEY_OFF
        return Self(command: command, type: type, status: status, control: control)
    }
}

public struct PlayParamPlaybackControllerVolume: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_SET_PARAM
    public var type: PlayInquiredType = .MUSIC_VOLUME
    public var volumeValue: UInt8

    public init(
        command: T1Command = .PLAY_SET_PARAM,
        type: PlayInquiredType = .MUSIC_VOLUME,
        volumeValue: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.volumeValue = volumeValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(volumeValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .MUSIC_VOLUME
        let volumeValue = try reader.readUInt8()
        return Self(command: command, type: type, volumeValue: volumeValue)
    }
}

public struct PlayParamPlaybackControllerVolumeWithMute: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_SET_PARAM
    public var type: PlayInquiredType = .MUSIC_VOLUME_WITH_MUTE
    public var volumeValue: UInt8
    public var muteSetting: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .PLAY_SET_PARAM,
        type: PlayInquiredType = .MUSIC_VOLUME_WITH_MUTE,
        volumeValue: UInt8 = 0,
        muteSetting: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.volumeValue = volumeValue
        self.muteSetting = muteSetting
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(volumeValue)
        writer.writeUInt8(muteSetting.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .MUSIC_VOLUME_WITH_MUTE
        let volumeValue = try reader.readUInt8()
        let muteSetting = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, volumeValue: volumeValue, muteSetting: muteSetting)
    }
}

public struct PlayParamPlayMode: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_SET_PARAM
    public var type: PlayInquiredType = .PLAY_MODE
    public var playMode: PlayMode

    public init(
        command: T1Command = .PLAY_SET_PARAM,
        type: PlayInquiredType = .PLAY_MODE,
        playMode: PlayMode = .PLAY_MODE_OFF
    ) {
        self.command = command
        self.type = type
        self.playMode = playMode
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(playMode.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAY_MODE
        let playMode = PlayMode(rawValue: try reader.readUInt8()) ?? .PLAY_MODE_OFF
        return Self(command: command, type: type, playMode: playMode)
    }
}

// MARK: - PlaybackName (MDRReadWritable sub-type)

public struct PlaybackName: Equatable, Sendable, MDRReadWritable {
    public var playbackNameStatus: PlaybackNameStatus
    public var playbackName: PrefixedString

    public init(
        playbackNameStatus: PlaybackNameStatus = .UNSETTLED,
        playbackName: PrefixedString = PrefixedString()
    ) {
        self.playbackNameStatus = playbackNameStatus
        self.playbackName = playbackName
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let playbackNameStatus = PlaybackNameStatus(rawValue: try reader.readUInt8()) ?? .UNSETTLED
        let playbackName = try PrefixedString.read(from: &reader)
        return Self(playbackNameStatus: playbackNameStatus, playbackName: playbackName)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(playbackNameStatus.rawValue)
        playbackName.write(to: &writer)
    }
}

// MARK: - PlayParamPlaybackControllerName

public struct PlayParamPlaybackControllerName: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .PLAY_RET_PARAM
    public var type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
    public var playbackNames: [PlaybackName]

    public init(
        command: T1Command = .PLAY_RET_PARAM,
        type: PlayInquiredType = .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
        playbackNames: [PlaybackName] = [PlaybackName(), PlaybackName(), PlaybackName(), PlaybackName()]
    ) {
        precondition(playbackNames.count == 4, "playbackNames must contain exactly 4 elements")
        self.command = command
        self.type = type
        self.playbackNames = playbackNames
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        for name in playbackNames {
            name.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PlayInquiredType(rawValue: try reader.readUInt8()) ?? .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT
        var playbackNames: [PlaybackName] = []
        playbackNames.reserveCapacity(4)
        for _ in 0..<4 {
            let name = try PlaybackName.read(from: &reader)
            playbackNames.append(name)
        }
        return Self(command: command, type: type, playbackNames: playbackNames)
    }
}
