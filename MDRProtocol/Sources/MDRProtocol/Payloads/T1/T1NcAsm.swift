import Foundation

// MARK: - NcAsm payload structs (from ProtocolV2T1.hpp)

public struct NcAsmGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .NCASM_GET_PARAM
    public var type: NcAsmInquiredType

    public init(command: T1Command = .NCASM_GET_PARAM, type: NcAsmInquiredType = .NC_ON_OFF) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = NcAsmInquiredType(rawValue: try reader.readUInt8()) ?? .NC_ON_OFF
        return Self(command: command, type: type)
    }
}

public struct NcAsmParamModeNcDualModeSwitchAsmSeamless: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .NCASM_SET_PARAM
    public var type: NcAsmInquiredType = .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS
    public var valueChangeStatus: ValueChangeStatus
    public var ncAsmTotalEffect: NcAsmOnOffValue
    public var ncAsmMode: NcAsmMode
    public var ambientSoundMode: AmbientSoundMode
    public var ambientSoundLevelValue: UInt8

    public init(
        command: T1Command = .NCASM_SET_PARAM,
        type: NcAsmInquiredType = .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS,
        valueChangeStatus: ValueChangeStatus = .CHANGED,
        ncAsmTotalEffect: NcAsmOnOffValue = .OFF,
        ncAsmMode: NcAsmMode = .NC,
        ambientSoundMode: AmbientSoundMode = .NORMAL,
        ambientSoundLevelValue: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.valueChangeStatus = valueChangeStatus
        self.ncAsmTotalEffect = ncAsmTotalEffect
        self.ncAsmMode = ncAsmMode
        self.ambientSoundMode = ambientSoundMode
        self.ambientSoundLevelValue = ambientSoundLevelValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(valueChangeStatus.rawValue)
        writer.writeUInt8(ncAsmTotalEffect.rawValue)
        writer.writeUInt8(ncAsmMode.rawValue)
        writer.writeUInt8(ambientSoundMode.rawValue)
        writer.writeUInt8(ambientSoundLevelValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = NcAsmInquiredType(rawValue: try reader.readUInt8()) ?? .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS
        let valueChangeStatus = ValueChangeStatus(rawValue: try reader.readUInt8()) ?? .CHANGED
        let ncAsmTotalEffect = NcAsmOnOffValue(rawValue: try reader.readUInt8()) ?? .OFF
        let ncAsmMode = NcAsmMode(rawValue: try reader.readUInt8()) ?? .NC
        let ambientSoundMode = AmbientSoundMode(rawValue: try reader.readUInt8()) ?? .NORMAL
        let ambientSoundLevelValue = try reader.readUInt8()
        return Self(
            command: command,
            type: type,
            valueChangeStatus: valueChangeStatus,
            ncAsmTotalEffect: ncAsmTotalEffect,
            ncAsmMode: ncAsmMode,
            ambientSoundMode: ambientSoundMode,
            ambientSoundLevelValue: ambientSoundLevelValue
        )
    }
}

public struct NcAsmParamModeNcDualModeSwitchAsmSeamlessNa: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .NCASM_SET_PARAM
    public var type: NcAsmInquiredType = .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA
    public var valueChangeStatus: ValueChangeStatus
    public var ncAsmTotalEffect: NcAsmOnOffValue
    public var ncAsmMode: NcAsmMode
    public var ambientSoundMode: AmbientSoundMode
    public var ambientSoundLevelValue: UInt8
    public var noiseAdaptiveOnOffValue: NcAsmOnOffValue
    public var noiseAdaptiveSensitivitySettings: NoiseAdaptiveSensitivity

    public init(
        command: T1Command = .NCASM_SET_PARAM,
        type: NcAsmInquiredType = .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA,
        valueChangeStatus: ValueChangeStatus = .CHANGED,
        ncAsmTotalEffect: NcAsmOnOffValue = .OFF,
        ncAsmMode: NcAsmMode = .NC,
        ambientSoundMode: AmbientSoundMode = .NORMAL,
        ambientSoundLevelValue: UInt8 = 0,
        noiseAdaptiveOnOffValue: NcAsmOnOffValue = .OFF,
        noiseAdaptiveSensitivitySettings: NoiseAdaptiveSensitivity = .STANDARD
    ) {
        self.command = command
        self.type = type
        self.valueChangeStatus = valueChangeStatus
        self.ncAsmTotalEffect = ncAsmTotalEffect
        self.ncAsmMode = ncAsmMode
        self.ambientSoundMode = ambientSoundMode
        self.ambientSoundLevelValue = ambientSoundLevelValue
        self.noiseAdaptiveOnOffValue = noiseAdaptiveOnOffValue
        self.noiseAdaptiveSensitivitySettings = noiseAdaptiveSensitivitySettings
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(valueChangeStatus.rawValue)
        writer.writeUInt8(ncAsmTotalEffect.rawValue)
        writer.writeUInt8(ncAsmMode.rawValue)
        writer.writeUInt8(ambientSoundMode.rawValue)
        writer.writeUInt8(ambientSoundLevelValue)
        writer.writeUInt8(noiseAdaptiveOnOffValue.rawValue)
        writer.writeUInt8(noiseAdaptiveSensitivitySettings.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = NcAsmInquiredType(rawValue: try reader.readUInt8()) ?? .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA
        let valueChangeStatus = ValueChangeStatus(rawValue: try reader.readUInt8()) ?? .CHANGED
        let ncAsmTotalEffect = NcAsmOnOffValue(rawValue: try reader.readUInt8()) ?? .OFF
        let ncAsmMode = NcAsmMode(rawValue: try reader.readUInt8()) ?? .NC
        let ambientSoundMode = AmbientSoundMode(rawValue: try reader.readUInt8()) ?? .NORMAL
        let ambientSoundLevelValue = try reader.readUInt8()
        let noiseAdaptiveOnOffValue = NcAsmOnOffValue(rawValue: try reader.readUInt8()) ?? .OFF
        let noiseAdaptiveSensitivitySettings = NoiseAdaptiveSensitivity(rawValue: try reader.readUInt8()) ?? .STANDARD
        return Self(
            command: command,
            type: type,
            valueChangeStatus: valueChangeStatus,
            ncAsmTotalEffect: ncAsmTotalEffect,
            ncAsmMode: ncAsmMode,
            ambientSoundMode: ambientSoundMode,
            ambientSoundLevelValue: ambientSoundLevelValue,
            noiseAdaptiveOnOffValue: noiseAdaptiveOnOffValue,
            noiseAdaptiveSensitivitySettings: noiseAdaptiveSensitivitySettings
        )
    }
}

public struct NcAsmParamAsmOnOff: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .NCASM_SET_PARAM
    public var type: NcAsmInquiredType = .ASM_ON_OFF
    public var valueChangeStatus: ValueChangeStatus
    public var ncAsmTotalEffect: NcAsmOnOffValue
    public var ambientSoundMode: AmbientSoundMode
    public var ambientSoundValue: NcAsmOnOffValue

    public init(
        command: T1Command = .NCASM_SET_PARAM,
        type: NcAsmInquiredType = .ASM_ON_OFF,
        valueChangeStatus: ValueChangeStatus = .CHANGED,
        ncAsmTotalEffect: NcAsmOnOffValue = .OFF,
        ambientSoundMode: AmbientSoundMode = .NORMAL,
        ambientSoundValue: NcAsmOnOffValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.valueChangeStatus = valueChangeStatus
        self.ncAsmTotalEffect = ncAsmTotalEffect
        self.ambientSoundMode = ambientSoundMode
        self.ambientSoundValue = ambientSoundValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(valueChangeStatus.rawValue)
        writer.writeUInt8(ncAsmTotalEffect.rawValue)
        writer.writeUInt8(ambientSoundMode.rawValue)
        writer.writeUInt8(ambientSoundValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = NcAsmInquiredType(rawValue: try reader.readUInt8()) ?? .ASM_ON_OFF
        let valueChangeStatus = ValueChangeStatus(rawValue: try reader.readUInt8()) ?? .CHANGED
        let ncAsmTotalEffect = NcAsmOnOffValue(rawValue: try reader.readUInt8()) ?? .OFF
        let ambientSoundMode = AmbientSoundMode(rawValue: try reader.readUInt8()) ?? .NORMAL
        let ambientSoundValue = NcAsmOnOffValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(
            command: command,
            type: type,
            valueChangeStatus: valueChangeStatus,
            ncAsmTotalEffect: ncAsmTotalEffect,
            ambientSoundMode: ambientSoundMode,
            ambientSoundValue: ambientSoundValue
        )
    }
}

public struct NcAsmParamAsmSeamless: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .NCASM_SET_PARAM
    public var type: NcAsmInquiredType = .ASM_SEAMLESS
    public var valueChangeStatus: ValueChangeStatus
    public var ncAsmTotalEffect: NcAsmOnOffValue
    public var ambientSoundMode: AmbientSoundMode
    public var ambientSoundLevelValue: UInt8

    public init(
        command: T1Command = .NCASM_SET_PARAM,
        type: NcAsmInquiredType = .ASM_SEAMLESS,
        valueChangeStatus: ValueChangeStatus = .CHANGED,
        ncAsmTotalEffect: NcAsmOnOffValue = .OFF,
        ambientSoundMode: AmbientSoundMode = .NORMAL,
        ambientSoundLevelValue: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.valueChangeStatus = valueChangeStatus
        self.ncAsmTotalEffect = ncAsmTotalEffect
        self.ambientSoundMode = ambientSoundMode
        self.ambientSoundLevelValue = ambientSoundLevelValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(valueChangeStatus.rawValue)
        writer.writeUInt8(ncAsmTotalEffect.rawValue)
        writer.writeUInt8(ambientSoundMode.rawValue)
        writer.writeUInt8(ambientSoundLevelValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = NcAsmInquiredType(rawValue: try reader.readUInt8()) ?? .ASM_SEAMLESS
        let valueChangeStatus = ValueChangeStatus(rawValue: try reader.readUInt8()) ?? .CHANGED
        let ncAsmTotalEffect = NcAsmOnOffValue(rawValue: try reader.readUInt8()) ?? .OFF
        let ambientSoundMode = AmbientSoundMode(rawValue: try reader.readUInt8()) ?? .NORMAL
        let ambientSoundLevelValue = try reader.readUInt8()
        return Self(
            command: command,
            type: type,
            valueChangeStatus: valueChangeStatus,
            ncAsmTotalEffect: ncAsmTotalEffect,
            ambientSoundMode: ambientSoundMode,
            ambientSoundLevelValue: ambientSoundLevelValue
        )
    }
}

public struct NcAsmParamNcAmbToggle: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .NCASM_SET_PARAM
    public var type: NcAsmInquiredType = .NC_AMB_TOGGLE
    public var function: Function

    public init(
        command: T1Command = .NCASM_SET_PARAM,
        type: NcAsmInquiredType = .NC_AMB_TOGGLE,
        function: Function = .NO_FUNCTION
    ) {
        self.command = command
        self.type = type
        self.function = function
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(function.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = NcAsmInquiredType(rawValue: try reader.readUInt8()) ?? .NC_AMB_TOGGLE
        let function = Function(rawValue: try reader.readUInt8()) ?? .NO_FUNCTION
        return Self(command: command, type: type, function: function)
    }
}
