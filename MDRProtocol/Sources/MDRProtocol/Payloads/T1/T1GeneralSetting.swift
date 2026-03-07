import Foundation

// MARK: - GeneralSetting payloads from ProtocolV2T1.hpp

// MARK: GsGetCapability

public struct GsGetCapability: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .GENERAL_SETTING_GET_CAPABILITY
    public var type: GsInquiredType = .GENERAL_SETTING1
    public var displayLanguage: DisplayLanguage = .UNDEFINED_LANGUAGE

    public init(
        command: T1Command = .GENERAL_SETTING_GET_CAPABILITY,
        type: GsInquiredType = .GENERAL_SETTING1,
        displayLanguage: DisplayLanguage = .UNDEFINED_LANGUAGE
    ) {
        self.command = command
        self.type = type
        self.displayLanguage = displayLanguage
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(displayLanguage.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = GsInquiredType(rawValue: try reader.readUInt8()) ?? .GENERAL_SETTING1
        let displayLanguage = DisplayLanguage(rawValue: try reader.readUInt8()) ?? .UNDEFINED_LANGUAGE
        return Self(command: command, type: type, displayLanguage: displayLanguage)
    }
}

// MARK: GsSettingInfo

/// Sub-struct: GsStringFormat + subject(PrefixedString) + summary(PrefixedString).
/// Matches C++ `GsSettingInfo` with EXTERN_READ_WRITE.
public struct GsSettingInfo: Equatable, Sendable, MDRReadWritable {
    public var stringFormat: GsStringFormat = .RAW_NAME
    public var subject: PrefixedString = PrefixedString()
    public var summary: PrefixedString = PrefixedString()

    public init(
        stringFormat: GsStringFormat = .RAW_NAME,
        subject: PrefixedString = PrefixedString(),
        summary: PrefixedString = PrefixedString()
    ) {
        self.stringFormat = stringFormat
        self.subject = subject
        self.summary = summary
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let stringFormat = GsStringFormat(rawValue: try reader.readUInt8()) ?? .RAW_NAME
        let subject = try PrefixedString.read(from: &reader)
        let summary = try PrefixedString.read(from: &reader)
        return Self(stringFormat: stringFormat, subject: subject, summary: summary)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(stringFormat.rawValue)
        subject.write(to: &writer)
        summary.write(to: &writer)
    }
}

// MARK: GsRetCapability (EXTERN)

public struct GsRetCapability: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .GENERAL_SETTING_RET_CAPABILITY
    public var type: GsInquiredType = .GENERAL_SETTING1
    public var settingType: GsSettingType = .BOOLEAN_TYPE
    public var settingInfo: GsSettingInfo = GsSettingInfo()

    public init(
        command: T1Command = .GENERAL_SETTING_RET_CAPABILITY,
        type: GsInquiredType = .GENERAL_SETTING1,
        settingType: GsSettingType = .BOOLEAN_TYPE,
        settingInfo: GsSettingInfo = GsSettingInfo()
    ) {
        self.command = command
        self.type = type
        self.settingType = settingType
        self.settingInfo = settingInfo
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingType.rawValue)
        settingInfo.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = GsInquiredType(rawValue: try reader.readUInt8()) ?? .GENERAL_SETTING1
        let settingType = GsSettingType(rawValue: try reader.readUInt8()) ?? .BOOLEAN_TYPE
        let settingInfo = try GsSettingInfo.read(from: &reader)
        return Self(
            command: command,
            type: type,
            settingType: settingType,
            settingInfo: settingInfo
        )
    }
}

// MARK: GsGetParam

public struct GsGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .GENERAL_SETTING_GET_PARAM
    public var type: GsInquiredType = .GENERAL_SETTING1

    public init(
        command: T1Command = .GENERAL_SETTING_GET_PARAM,
        type: GsInquiredType = .GENERAL_SETTING1
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
        let type = GsInquiredType(rawValue: try reader.readUInt8()) ?? .GENERAL_SETTING1
        return Self(command: command, type: type)
    }
}

// MARK: GsParamBase

/// Base struct for GsParam payloads: command + GsInquiredType + GsSettingType.
/// Matches C++ `GsParamBase`.
public struct GsParamBase: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .GENERAL_SETTING_RET_PARAM
    public var type: GsInquiredType = .GENERAL_SETTING1
    public var settingType: GsSettingType = .BOOLEAN_TYPE

    public init(
        command: T1Command = .GENERAL_SETTING_RET_PARAM,
        type: GsInquiredType = .GENERAL_SETTING1,
        settingType: GsSettingType = .BOOLEAN_TYPE
    ) {
        self.command = command
        self.type = type
        self.settingType = settingType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(settingType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = GsInquiredType(rawValue: try reader.readUInt8()) ?? .GENERAL_SETTING1
        let settingType = GsSettingType(rawValue: try reader.readUInt8()) ?? .BOOLEAN_TYPE
        return Self(command: command, type: type, settingType: settingType)
    }
}

// MARK: GsParamBoolean

/// BOOLEAN_TYPE general setting param.
public struct GsParamBoolean: Equatable, Sendable, MDRSerializable {
    public var base: GsParamBase = GsParamBase(
        command: .GENERAL_SETTING_SET_PARAM,
        type: .GENERAL_SETTING1,
        settingType: .BOOLEAN_TYPE
    )
    public var settingValue: GsSettingValue = .ON

    public init(
        base: GsParamBase = GsParamBase(
            command: .GENERAL_SETTING_SET_PARAM,
            type: .GENERAL_SETTING1,
            settingType: .BOOLEAN_TYPE
        ),
        settingValue: GsSettingValue = .ON
    ) {
        self.base = base
        self.settingValue = settingValue
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(settingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try GsParamBase.deserialize(from: &reader)
        let settingValue = GsSettingValue(rawValue: try reader.readUInt8()) ?? .ON
        return Self(base: base, settingValue: settingValue)
    }
}

// MARK: GsParamList

/// LIST_TYPE general setting param.
public struct GsParamList: Equatable, Sendable, MDRSerializable {
    public var base: GsParamBase = GsParamBase(
        command: .GENERAL_SETTING_RET_PARAM,
        type: .GENERAL_SETTING1,
        settingType: .LIST_TYPE
    )
    public var currentElementIndex: UInt8 = 0

    public init(
        base: GsParamBase = GsParamBase(
            command: .GENERAL_SETTING_RET_PARAM,
            type: .GENERAL_SETTING1,
            settingType: .LIST_TYPE
        ),
        currentElementIndex: UInt8 = 0
    ) {
        self.base = base
        self.currentElementIndex = currentElementIndex
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(currentElementIndex)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try GsParamBase.deserialize(from: &reader)
        let currentElementIndex = try reader.readUInt8()
        return Self(base: base, currentElementIndex: currentElementIndex)
    }
}
