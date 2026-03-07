import Foundation

// MARK: - Alert payload structs (from ProtocolV2T1.hpp)

// MARK: AlertGetStatus

public struct AlertGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_GET_STATUS
    public var type: AlertInquiredType

    public init(
        command: T1Command = .ALERT_GET_STATUS,
        type: AlertInquiredType = .FIXED_MESSAGE
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
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_MESSAGE
        return Self(command: command, type: type)
    }
}

// MARK: AlertStatusLEAudioAlertNotification

public struct AlertStatusLEAudioAlertNotification: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_RET_STATUS
    public var type: AlertInquiredType = .LE_AUDIO_ALERT_NOTIFICATION
    public var leAudioAlertStatus: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .ALERT_RET_STATUS,
        type: AlertInquiredType = .LE_AUDIO_ALERT_NOTIFICATION,
        leAudioAlertStatus: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.leAudioAlertStatus = leAudioAlertStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(leAudioAlertStatus.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .LE_AUDIO_ALERT_NOTIFICATION
        let leAudioAlertStatus = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, leAudioAlertStatus: leAudioAlertStatus)
    }
}

// MARK: AlertRetStatusVoiceAssistant (EXTERN)

public struct AlertRetStatusVoiceAssistant: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_RET_STATUS
    public var type: AlertInquiredType = .VOICE_ASSISTANT_ALERT_NOTIFICATION
    public var voiceAssistants: PodArray<UInt8>

    public init(
        command: T1Command = .ALERT_RET_STATUS,
        type: AlertInquiredType = .VOICE_ASSISTANT_ALERT_NOTIFICATION,
        voiceAssistants: PodArray<UInt8> = PodArray()
    ) {
        self.command = command
        self.type = type
        self.voiceAssistants = voiceAssistants
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        voiceAssistants.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .VOICE_ASSISTANT_ALERT_NOTIFICATION
        let voiceAssistants = try PodArray<UInt8>.read(from: &reader)
        return Self(command: command, type: type, voiceAssistants: voiceAssistants)
    }
}

// MARK: AlertSetStatusFixedMessage

public struct AlertSetStatusFixedMessage: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_STATUS
    public var type: AlertInquiredType = .FIXED_MESSAGE
    public var status: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .ALERT_SET_STATUS,
        type: AlertInquiredType = .FIXED_MESSAGE,
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
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_MESSAGE
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, status: status)
    }
}

// MARK: AlertSetStatusAppBecomesForeground

public struct AlertSetStatusAppBecomesForeground: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_STATUS
    public var type: AlertInquiredType = .APP_BECOMES_FOREGROUND
    public var status: MessageMdrV2EnableDisable

    public init(
        command: T1Command = .ALERT_SET_STATUS,
        type: AlertInquiredType = .APP_BECOMES_FOREGROUND,
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
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .APP_BECOMES_FOREGROUND
        let status = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, status: status)
    }
}

// MARK: AlertSetStatusLEAudioAlertNotification

public struct AlertSetStatusLEAudioAlertNotification: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_STATUS
    public var type: AlertInquiredType = .LE_AUDIO_ALERT_NOTIFICATION
    public var leAudioAlertStatus: MessageMdrV2EnableDisable
    public var confirmationType: ConfirmationType

    public init(
        command: T1Command = .ALERT_SET_STATUS,
        type: AlertInquiredType = .LE_AUDIO_ALERT_NOTIFICATION,
        leAudioAlertStatus: MessageMdrV2EnableDisable = .DISABLE,
        confirmationType: ConfirmationType = .CONFIRMED
    ) {
        self.command = command
        self.type = type
        self.leAudioAlertStatus = leAudioAlertStatus
        self.confirmationType = confirmationType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(leAudioAlertStatus.rawValue)
        writer.writeUInt8(confirmationType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .LE_AUDIO_ALERT_NOTIFICATION
        let leAudioAlertStatus = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        let confirmationType = ConfirmationType(rawValue: try reader.readUInt8()) ?? .CONFIRMED
        return Self(command: command, type: type, leAudioAlertStatus: leAudioAlertStatus, confirmationType: confirmationType)
    }
}

// MARK: AlertSetParamFixedMessage

public struct AlertSetParamFixedMessage: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_PARAM
    public var type: AlertInquiredType = .FIXED_MESSAGE
    public var messageType: AlertMessageType
    public var actionType: AlertAction

    public init(
        command: T1Command = .ALERT_SET_PARAM,
        type: AlertInquiredType = .FIXED_MESSAGE,
        messageType: AlertMessageType = .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
        actionType: AlertAction = .NEGATIVE
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.actionType = actionType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(actionType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_MESSAGE
        let messageType = AlertMessageType(rawValue: try reader.readUInt8()) ?? .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE
        let actionType = AlertAction(rawValue: try reader.readUInt8()) ?? .NEGATIVE
        return Self(command: command, type: type, messageType: messageType, actionType: actionType)
    }
}

// MARK: AlertSetParamVibrator

public struct AlertSetParamVibrator: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_PARAM
    public var type: AlertInquiredType = .VIBRATOR_ALERT_NOTIFICATION
    public var vibrationType: VibrationType

    public init(
        command: T1Command = .ALERT_SET_PARAM,
        type: AlertInquiredType = .VIBRATOR_ALERT_NOTIFICATION,
        vibrationType: VibrationType = .NO_PATTERN_SPECIFIED
    ) {
        self.command = command
        self.type = type
        self.vibrationType = vibrationType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(vibrationType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .VIBRATOR_ALERT_NOTIFICATION
        let vibrationType = VibrationType(rawValue: try reader.readUInt8()) ?? .NO_PATTERN_SPECIFIED
        return Self(command: command, type: type, vibrationType: vibrationType)
    }
}

// MARK: AlertSetParamFixedMessageWithLeftRightSelection

public struct AlertSetParamFixedMessageWithLeftRightSelection: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_PARAM
    public var type: AlertInquiredType = .FIXED_MESSAGE_WITH_LEFT_RIGHT_SELECTION
    public var messageType: AlertMessageTypeWithLeftRightSelection
    public var actionType: AlertLeftRightAction

    public init(
        command: T1Command = .ALERT_SET_PARAM,
        type: AlertInquiredType = .FIXED_MESSAGE_WITH_LEFT_RIGHT_SELECTION,
        messageType: AlertMessageTypeWithLeftRightSelection = .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_BUTTON,
        actionType: AlertLeftRightAction = .NEGATIVE
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.actionType = actionType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(actionType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_MESSAGE_WITH_LEFT_RIGHT_SELECTION
        let messageType = AlertMessageTypeWithLeftRightSelection(rawValue: try reader.readUInt8()) ?? .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_BUTTON
        let actionType = AlertLeftRightAction(rawValue: try reader.readUInt8()) ?? .NEGATIVE
        return Self(command: command, type: type, messageType: messageType, actionType: actionType)
    }
}

// MARK: AlertSetParamAppBecomesForeground

public struct AlertSetParamAppBecomesForeground: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_PARAM
    public var type: AlertInquiredType = .APP_BECOMES_FOREGROUND
    public var messageType: AlertMessageType
    public var actionType: AlertAction

    public init(
        command: T1Command = .ALERT_SET_PARAM,
        type: AlertInquiredType = .APP_BECOMES_FOREGROUND,
        messageType: AlertMessageType = .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
        actionType: AlertAction = .NEGATIVE
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.actionType = actionType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(actionType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .APP_BECOMES_FOREGROUND
        let messageType = AlertMessageType(rawValue: try reader.readUInt8()) ?? .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE
        let actionType = AlertAction(rawValue: try reader.readUInt8()) ?? .NEGATIVE
        return Self(command: command, type: type, messageType: messageType, actionType: actionType)
    }
}

// MARK: AlertSetParamFlexibleMessage

public struct AlertSetParamFlexibleMessage: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_SET_PARAM
    public var type: AlertInquiredType = .FLEXIBLE_MESSAGE
    public var messageType: AlertFlexibleMessageType
    public var actionType: AlertAction

    public init(
        command: T1Command = .ALERT_SET_PARAM,
        type: AlertInquiredType = .FLEXIBLE_MESSAGE,
        messageType: AlertFlexibleMessageType = .BATTERY_CONSUMPTION_INCREASE_DUE_TO_SIMULTANEOUS_3_SETTINGS,
        actionType: AlertAction = .NEGATIVE
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.actionType = actionType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(actionType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FLEXIBLE_MESSAGE
        let messageType = AlertFlexibleMessageType(rawValue: try reader.readUInt8()) ?? .BATTERY_CONSUMPTION_INCREASE_DUE_TO_SIMULTANEOUS_3_SETTINGS
        let actionType = AlertAction(rawValue: try reader.readUInt8()) ?? .NEGATIVE
        return Self(command: command, type: type, messageType: messageType, actionType: actionType)
    }
}

// MARK: AlertNotifyParamFixedMessage

public struct AlertNotifyParamFixedMessage: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_NTFY_PARAM
    public var type: AlertInquiredType = .FIXED_MESSAGE
    public var messageType: AlertMessageType
    public var actionType: AlertActionType

    public init(
        command: T1Command = .ALERT_NTFY_PARAM,
        type: AlertInquiredType = .FIXED_MESSAGE,
        messageType: AlertMessageType = .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
        actionType: AlertActionType = .CONFIRMATION_ONLY
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.actionType = actionType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(actionType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_MESSAGE
        let messageType = AlertMessageType(rawValue: try reader.readUInt8()) ?? .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE
        let actionType = AlertActionType(rawValue: try reader.readUInt8()) ?? .CONFIRMATION_ONLY
        return Self(command: command, type: type, messageType: messageType, actionType: actionType)
    }
}

// MARK: AlertNotifyParamFixedMessageWithLeftRightSelection

public struct AlertNotifyParamFixedMessageWithLeftRightSelection: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_NTFY_PARAM
    public var type: AlertInquiredType = .FIXED_MESSAGE_WITH_LEFT_RIGHT_SELECTION
    public var messageType: AlertMessageTypeWithLeftRightSelection
    public var defaultSelectedValue: DefaultSelectedLeftRightValue

    public init(
        command: T1Command = .ALERT_NTFY_PARAM,
        type: AlertInquiredType = .FIXED_MESSAGE_WITH_LEFT_RIGHT_SELECTION,
        messageType: AlertMessageTypeWithLeftRightSelection = .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_BUTTON,
        defaultSelectedValue: DefaultSelectedLeftRightValue = .LEFT
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.defaultSelectedValue = defaultSelectedValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(defaultSelectedValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_MESSAGE_WITH_LEFT_RIGHT_SELECTION
        let messageType = AlertMessageTypeWithLeftRightSelection(rawValue: try reader.readUInt8()) ?? .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_BUTTON
        let defaultSelectedValue = DefaultSelectedLeftRightValue(rawValue: try reader.readUInt8()) ?? .LEFT
        return Self(command: command, type: type, messageType: messageType, defaultSelectedValue: defaultSelectedValue)
    }
}

// MARK: AlertNotifyParamAppBecomesForeground

public struct AlertNotifyParamAppBecomesForeground: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .ALERT_NTFY_PARAM
    public var type: AlertInquiredType = .APP_BECOMES_FOREGROUND
    public var messageType: AlertMessageType
    public var actionType: AlertActionType

    public init(
        command: T1Command = .ALERT_NTFY_PARAM,
        type: AlertInquiredType = .APP_BECOMES_FOREGROUND,
        messageType: AlertMessageType = .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
        actionType: AlertActionType = .CONFIRMATION_ONLY
    ) {
        self.command = command
        self.type = type
        self.messageType = messageType
        self.actionType = actionType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(messageType.rawValue)
        writer.writeUInt8(actionType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = AlertInquiredType(rawValue: try reader.readUInt8()) ?? .APP_BECOMES_FOREGROUND
        let messageType = AlertMessageType(rawValue: try reader.readUInt8()) ?? .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE
        let actionType = AlertActionType(rawValue: try reader.readUInt8()) ?? .CONFIRMATION_ONLY
        return Self(command: command, type: type, messageType: messageType, actionType: actionType)
    }
}
