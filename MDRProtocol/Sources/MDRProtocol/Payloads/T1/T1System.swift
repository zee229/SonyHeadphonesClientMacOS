import Foundation

// MARK: - System payloads from ProtocolV2T1.hpp

// MARK: SystemGetParam

public struct SystemGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .SYSTEM_GET_PARAM
    public var type: SystemInquiredType

    public init(
        command: T1Command = .SYSTEM_GET_PARAM,
        type: SystemInquiredType = .VIBRATOR
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
        let type = SystemInquiredType(rawValue: try reader.readUInt8()) ?? .VIBRATOR
        return Self(command: command, type: type)
    }
}

// MARK: SystemBase

/// Base struct for System PARAM payloads: command + SystemInquiredType.
/// Matches C++ `SystemBase`.
public struct SystemBase: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .SYSTEM_SET_PARAM
    public var type: SystemInquiredType = .VIBRATOR

    public init(
        command: T1Command = .SYSTEM_SET_PARAM,
        type: SystemInquiredType = .VIBRATOR
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
        let type = SystemInquiredType(rawValue: try reader.readUInt8()) ?? .VIBRATOR
        return Self(command: command, type: type)
    }
}

// MARK: SystemParamCommon

/// Used for VIBRATOR, PLAYBACK_CONTROL_BY_WEARING, VOICE_ASSISTANT_WAKE_WORD, AUTO_VOLUME, HEAD_GESTURE_ON_OFF.
public struct SystemParamCommon: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(command: .SYSTEM_RET_PARAM)
    public var settingValue: MessageMdrV2EnableDisable = .ENABLE

    public init(
        base: SystemBase = SystemBase(command: .SYSTEM_RET_PARAM),
        settingValue: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.base = base
        self.settingValue = settingValue
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(settingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let settingValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(base: base, settingValue: settingValue)
    }
}

// MARK: SystemParamSmartTalking

/// Used for SMART_TALKING_MODE_TYPE1, SMART_TALKING_MODE_TYPE2.
public struct SystemParamSmartTalking: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_SET_PARAM,
        type: .SMART_TALKING_MODE_TYPE1
    )
    public var onOffValue: MessageMdrV2EnableDisable = .ENABLE
    public var previewModeOnOffValue: MessageMdrV2EnableDisable = .ENABLE

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_SET_PARAM,
            type: .SMART_TALKING_MODE_TYPE1
        ),
        onOffValue: MessageMdrV2EnableDisable = .ENABLE,
        previewModeOnOffValue: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.base = base
        self.onOffValue = onOffValue
        self.previewModeOnOffValue = previewModeOnOffValue
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(onOffValue.rawValue)
        writer.writeUInt8(previewModeOnOffValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let onOffValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let previewModeOnOffValue = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(base: base, onOffValue: onOffValue, previewModeOnOffValue: previewModeOnOffValue)
    }
}

// MARK: SystemParamAssignableSettings (EXTERN)

/// ASSIGNABLE_SETTINGS. Uses PodArray<UInt8> (count-prefixed, Preset is UInt8).
public struct SystemParamAssignableSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_SET_PARAM,
        type: .ASSIGNABLE_SETTINGS
    )
    public var presets: PodArray<UInt8> = PodArray()

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_SET_PARAM,
            type: .ASSIGNABLE_SETTINGS
        ),
        presets: PodArray<UInt8> = PodArray()
    ) {
        self.base = base
        self.presets = presets
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        presets.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let presets = try PodArray<UInt8>.read(from: &reader)
        return Self(base: base, presets: presets)
    }
}

// MARK: SystemParamVoiceAssistantSettings

/// VOICE_ASSISTANT_SETTINGS.
public struct SystemParamVoiceAssistantSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_RET_PARAM,
        type: .VOICE_ASSISTANT_SETTINGS
    )
    public var voiceAssistant: VoiceAssistant = .NO_FUNCTION

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_RET_PARAM,
            type: .VOICE_ASSISTANT_SETTINGS
        ),
        voiceAssistant: VoiceAssistant = .NO_FUNCTION
    ) {
        self.base = base
        self.voiceAssistant = voiceAssistant
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(voiceAssistant.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let voiceAssistant = VoiceAssistant(rawValue: try reader.readUInt8()) ?? .NO_FUNCTION
        return Self(base: base, voiceAssistant: voiceAssistant)
    }
}

// MARK: SystemParamWearingStatusDetector

/// WEARING_STATUS_DETECTOR (RET/NTFY variant).
public struct SystemParamWearingStatusDetector: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_RET_PARAM,
        type: .WEARING_STATUS_DETECTOR
    )
    public var operationStatus: EarpieceFittingDetectionOperationStatus = .DETECTION_IS_NOT_STARTED
    public var errorCode: EarpieceFittingDetectionOperationErrorCode = .NO_ERROR
    public var numOfSelectedEarpieces: UInt8 = 0
    public var indexOfCurrentDetection: UInt8 = 0
    public var currentDetectingSeries: EarpieceSeries = .OTHER
    public var earpieceSize: EarpieceSize = .NOT_DETERMINED

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_RET_PARAM,
            type: .WEARING_STATUS_DETECTOR
        ),
        operationStatus: EarpieceFittingDetectionOperationStatus = .DETECTION_IS_NOT_STARTED,
        errorCode: EarpieceFittingDetectionOperationErrorCode = .NO_ERROR,
        numOfSelectedEarpieces: UInt8 = 0,
        indexOfCurrentDetection: UInt8 = 0,
        currentDetectingSeries: EarpieceSeries = .OTHER,
        earpieceSize: EarpieceSize = .NOT_DETERMINED
    ) {
        self.base = base
        self.operationStatus = operationStatus
        self.errorCode = errorCode
        self.numOfSelectedEarpieces = numOfSelectedEarpieces
        self.indexOfCurrentDetection = indexOfCurrentDetection
        self.currentDetectingSeries = currentDetectingSeries
        self.earpieceSize = earpieceSize
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(operationStatus.rawValue)
        writer.writeUInt8(errorCode.rawValue)
        writer.writeUInt8(numOfSelectedEarpieces)
        writer.writeUInt8(indexOfCurrentDetection)
        writer.writeUInt8(currentDetectingSeries.rawValue)
        writer.writeUInt8(earpieceSize.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let operationStatus = EarpieceFittingDetectionOperationStatus(rawValue: try reader.readUInt8()) ?? .DETECTION_IS_NOT_STARTED
        let errorCode = EarpieceFittingDetectionOperationErrorCode(rawValue: try reader.readUInt8()) ?? .NO_ERROR
        let numOfSelectedEarpieces = try reader.readUInt8()
        let indexOfCurrentDetection = try reader.readUInt8()
        let currentDetectingSeries = EarpieceSeries(rawValue: try reader.readUInt8()) ?? .OTHER
        let earpieceSize = EarpieceSize(rawValue: try reader.readUInt8()) ?? .NOT_DETERMINED
        return Self(
            base: base,
            operationStatus: operationStatus,
            errorCode: errorCode,
            numOfSelectedEarpieces: numOfSelectedEarpieces,
            indexOfCurrentDetection: indexOfCurrentDetection,
            currentDetectingSeries: currentDetectingSeries,
            earpieceSize: earpieceSize
        )
    }
}

// MARK: SystemParamEarpieceSelection

/// EARPIECE_SELECTION.
public struct SystemParamEarpieceSelection: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_RET_PARAM,
        type: .EARPIECE_SELECTION
    )
    public var series: EarpieceSeries = .OTHER

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_RET_PARAM,
            type: .EARPIECE_SELECTION
        ),
        series: EarpieceSeries = .OTHER
    ) {
        self.base = base
        self.series = series
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(series.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let series = EarpieceSeries(rawValue: try reader.readUInt8()) ?? .OTHER
        return Self(base: base, series: series)
    }
}

// MARK: SystemParamCallSettings

/// CALL_SETTINGS.
public struct SystemParamCallSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_RET_PARAM,
        type: .CALL_SETTINGS
    )
    public var selfVoiceOnOff: MessageMdrV2EnableDisable = .ENABLE
    public var selfVoiceVolume: UInt8 = 0
    public var callVoiceVolume: UInt8 = 0

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_RET_PARAM,
            type: .CALL_SETTINGS
        ),
        selfVoiceOnOff: MessageMdrV2EnableDisable = .ENABLE,
        selfVoiceVolume: UInt8 = 0,
        callVoiceVolume: UInt8 = 0
    ) {
        self.base = base
        self.selfVoiceOnOff = selfVoiceOnOff
        self.selfVoiceVolume = selfVoiceVolume
        self.callVoiceVolume = callVoiceVolume
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(selfVoiceOnOff.rawValue)
        writer.writeUInt8(selfVoiceVolume)
        writer.writeUInt8(callVoiceVolume)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let selfVoiceOnOff = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let selfVoiceVolume = try reader.readUInt8()
        let callVoiceVolume = try reader.readUInt8()
        return Self(
            base: base,
            selfVoiceOnOff: selfVoiceOnOff,
            selfVoiceVolume: selfVoiceVolume,
            callVoiceVolume: callVoiceVolume
        )
    }
}

// MARK: SystemParamAssignableSettingsWithLimit (EXTERN)

/// ASSIGNABLE_SETTINGS_WITH_LIMITATION. Uses PodArray<UInt8>.
public struct SystemParamAssignableSettingsWithLimit: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_RET_PARAM,
        type: .ASSIGNABLE_SETTINGS_WITH_LIMITATION
    )
    public var presets: PodArray<UInt8> = PodArray()

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_RET_PARAM,
            type: .ASSIGNABLE_SETTINGS_WITH_LIMITATION
        ),
        presets: PodArray<UInt8> = PodArray()
    ) {
        self.base = base
        self.presets = presets
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        presets.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let presets = try PodArray<UInt8>.read(from: &reader)
        return Self(base: base, presets: presets)
    }
}

// MARK: SystemParamHeadGestureTraining

/// HEAD_GESTURE_TRAINING.
public struct SystemParamHeadGestureTraining: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_RET_PARAM,
        type: .HEAD_GESTURE_TRAINING
    )
    public var headGestureAction: HeadGestureAction = .NOD

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_RET_PARAM,
            type: .HEAD_GESTURE_TRAINING
        ),
        headGestureAction: HeadGestureAction = .NOD
    ) {
        self.base = base
        self.headGestureAction = headGestureAction
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(headGestureAction.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let headGestureAction = HeadGestureAction(rawValue: try reader.readUInt8()) ?? .NOD
        return Self(base: base, headGestureAction: headGestureAction)
    }
}

// MARK: SystemSetParamWearingStatusDetector

/// WEARING_STATUS_DETECTOR (SET variant).
public struct SystemSetParamWearingStatusDetector: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_SET_PARAM,
        type: .WEARING_STATUS_DETECTOR
    )
    public var operation: EarpieceFittingDetectionOperation = .DETECTION_START
    public var indexOfCurrentDetection: UInt8 = 0
    public var currentDetectionSeries: EarpieceSeries = .OTHER
    public var currentDetectionSize: EarpieceSize = .NOT_DETERMINED

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_SET_PARAM,
            type: .WEARING_STATUS_DETECTOR
        ),
        operation: EarpieceFittingDetectionOperation = .DETECTION_START,
        indexOfCurrentDetection: UInt8 = 0,
        currentDetectionSeries: EarpieceSeries = .OTHER,
        currentDetectionSize: EarpieceSize = .NOT_DETERMINED
    ) {
        self.base = base
        self.operation = operation
        self.indexOfCurrentDetection = indexOfCurrentDetection
        self.currentDetectionSeries = currentDetectionSeries
        self.currentDetectionSize = currentDetectionSize
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(operation.rawValue)
        writer.writeUInt8(indexOfCurrentDetection)
        writer.writeUInt8(currentDetectionSeries.rawValue)
        writer.writeUInt8(currentDetectionSize.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let operation = EarpieceFittingDetectionOperation(rawValue: try reader.readUInt8()) ?? .DETECTION_START
        let indexOfCurrentDetection = try reader.readUInt8()
        let currentDetectionSeries = EarpieceSeries(rawValue: try reader.readUInt8()) ?? .OTHER
        let currentDetectionSize = EarpieceSize(rawValue: try reader.readUInt8()) ?? .NOT_DETERMINED
        return Self(
            base: base,
            operation: operation,
            indexOfCurrentDetection: indexOfCurrentDetection,
            currentDetectionSeries: currentDetectionSeries,
            currentDetectionSize: currentDetectionSize
        )
    }
}

// MARK: SystemSetParamResetSettings

/// RESET_SETTINGS (SET variant).
public struct SystemSetParamResetSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_SET_PARAM,
        type: .RESET_SETTINGS
    )
    public var resetType: ResetType = .SETTINGS_ONLY

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_SET_PARAM,
            type: .RESET_SETTINGS
        ),
        resetType: ResetType = .SETTINGS_ONLY
    ) {
        self.base = base
        self.resetType = resetType
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(resetType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let resetType = ResetType(rawValue: try reader.readUInt8()) ?? .SETTINGS_ONLY
        return Self(base: base, resetType: resetType)
    }
}

// MARK: SystemNotifyParamResetSettings

/// RESET_SETTINGS (NTFY variant).
public struct SystemNotifyParamResetSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_NTFY_PARAM,
        type: .RESET_SETTINGS
    )
    public var resetResult: ResetResult = .SUCCESS

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_NTFY_PARAM,
            type: .RESET_SETTINGS
        ),
        resetResult: ResetResult = .SUCCESS
    ) {
        self.base = base
        self.resetResult = resetResult
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(resetResult.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let resetResult = ResetResult(rawValue: try reader.readUInt8()) ?? .SUCCESS
        return Self(base: base, resetResult: resetResult)
    }
}

// MARK: SystemNotifyParamFaceTapTestMode

/// FACE_TAP_TEST_MODE (NTFY variant).
public struct SystemNotifyParamFaceTapTestMode: Equatable, Sendable, MDRSerializable {
    public var base: SystemBase = SystemBase(
        command: .SYSTEM_NTFY_PARAM,
        type: .FACE_TAP_TEST_MODE
    )
    public var key: FaceTapKey = .LEFT_SIDE_KEY
    public var action: FaceTapAction = .DOUBLE_TAP

    public init(
        base: SystemBase = SystemBase(
            command: .SYSTEM_NTFY_PARAM,
            type: .FACE_TAP_TEST_MODE
        ),
        key: FaceTapKey = .LEFT_SIDE_KEY,
        action: FaceTapAction = .DOUBLE_TAP
    ) {
        self.base = base
        self.key = key
        self.action = action
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(key.rawValue)
        writer.writeUInt8(action.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemBase.deserialize(from: &reader)
        let key = FaceTapKey(rawValue: try reader.readUInt8()) ?? .LEFT_SIDE_KEY
        let action = FaceTapAction(rawValue: try reader.readUInt8()) ?? .DOUBLE_TAP
        return Self(base: base, key: key, action: action)
    }
}

// MARK: - Extended System payloads (EXT_PARAM)

// MARK: SystemGetExtParam

public struct SystemGetExtParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .SYSTEM_GET_EXT_PARAM
    public var type: SystemInquiredType

    public init(
        command: T1Command = .SYSTEM_GET_EXT_PARAM,
        type: SystemInquiredType = .VIBRATOR
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
        let type = SystemInquiredType(rawValue: try reader.readUInt8()) ?? .VIBRATOR
        return Self(command: command, type: type)
    }
}

// MARK: SystemExtBase

/// Base struct for System EXT_PARAM payloads: command + SystemInquiredType.
/// Matches C++ `SystemExtBase`.
public struct SystemExtBase: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .SYSTEM_RET_EXT_PARAM
    public var type: SystemInquiredType = .VIBRATOR

    public init(
        command: T1Command = .SYSTEM_RET_EXT_PARAM,
        type: SystemInquiredType = .VIBRATOR
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
        let type = SystemInquiredType(rawValue: try reader.readUInt8()) ?? .VIBRATOR
        return Self(command: command, type: type)
    }
}

// MARK: SystemExtParamSmartTalkingMode1

/// SMART_TALKING_MODE_TYPE1 extended param.
public struct SystemExtParamSmartTalkingMode1: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_RET_EXT_PARAM,
        type: .SMART_TALKING_MODE_TYPE1
    )
    public var detectSensitivity: DetectSensitivity = .AUTO
    public var voiceFocus: MessageMdrV2EnableDisable = .ENABLE
    public var modeOffTime: ModeOutTime = .FAST

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_RET_EXT_PARAM,
            type: .SMART_TALKING_MODE_TYPE1
        ),
        detectSensitivity: DetectSensitivity = .AUTO,
        voiceFocus: MessageMdrV2EnableDisable = .ENABLE,
        modeOffTime: ModeOutTime = .FAST
    ) {
        self.base = base
        self.detectSensitivity = detectSensitivity
        self.voiceFocus = voiceFocus
        self.modeOffTime = modeOffTime
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(detectSensitivity.rawValue)
        writer.writeUInt8(voiceFocus.rawValue)
        writer.writeUInt8(modeOffTime.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let detectSensitivity = DetectSensitivity(rawValue: try reader.readUInt8()) ?? .AUTO
        let voiceFocus = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let modeOffTime = ModeOutTime(rawValue: try reader.readUInt8()) ?? .FAST
        return Self(
            base: base,
            detectSensitivity: detectSensitivity,
            voiceFocus: voiceFocus,
            modeOffTime: modeOffTime
        )
    }
}

// MARK: AssignableSettingsAction

/// Sub-struct: Action + Function. 2-byte POD in C++.
public struct AssignableSettingsAction: Equatable, Sendable, MDRReadWritable {
    public var action: Action = .SINGLE_TAP
    public var function: Function = .NO_FUNCTION

    public init(action: Action = .SINGLE_TAP, function: Function = .NO_FUNCTION) {
        self.action = action
        self.function = function
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let action = Action(rawValue: try reader.readUInt8()) ?? .SINGLE_TAP
        let function = Function(rawValue: try reader.readUInt8()) ?? .NO_FUNCTION
        return Self(action: action, function: function)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(action.rawValue)
        writer.writeUInt8(function.rawValue)
    }
}

// MARK: AssignableSettingsPreset

/// Sub-struct: Preset + count-prefixed array of AssignableSettingsAction.
/// C++ uses `MDRPodArray<AssignableSettingsAction>` (1-byte count prefix).
public struct AssignableSettingsPreset: Equatable, Sendable, MDRReadWritable {
    public var preset: Preset = .NO_FUNCTION
    public var actions: MDRArray<AssignableSettingsAction> = MDRArray()

    public init(
        preset: Preset = .NO_FUNCTION,
        actions: MDRArray<AssignableSettingsAction> = MDRArray()
    ) {
        self.preset = preset
        self.actions = actions
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let preset = Preset(rawValue: try reader.readUInt8()) ?? .NO_FUNCTION
        let actions = try MDRArray<AssignableSettingsAction>.read(from: &reader)
        return Self(preset: preset, actions: actions)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(preset.rawValue)
        actions.write(to: &writer)
    }
}

// MARK: SystemExtParamAssignableSettings (EXTERN)

/// ASSIGNABLE_SETTINGS extended param. Uses MDRArray<AssignableSettingsPreset> (1-byte count prefix).
public struct SystemExtParamAssignableSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_RET_EXT_PARAM,
        type: .ASSIGNABLE_SETTINGS
    )
    public var presets: MDRArray<AssignableSettingsPreset> = MDRArray()

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_RET_EXT_PARAM,
            type: .ASSIGNABLE_SETTINGS
        ),
        presets: MDRArray<AssignableSettingsPreset> = MDRArray()
    ) {
        self.base = base
        self.presets = presets
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        presets.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let presets = try MDRArray<AssignableSettingsPreset>.read(from: &reader)
        return Self(base: base, presets: presets)
    }
}

// MARK: SystemExtParamWearingStatusDetector

/// WEARING_STATUS_DETECTOR extended param.
public struct SystemExtParamWearingStatusDetector: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_RET_EXT_PARAM,
        type: .WEARING_STATUS_DETECTOR
    )
    public var fittingResultLeft: EarpieceFittingDetectionResult = .GOOD
    public var fittingResultRight: EarpieceFittingDetectionResult = .GOOD
    public var bestEarpieceSeriesLeft: EarpieceSeries = .OTHER
    public var bestEarpieceSeriesRight: EarpieceSeries = .OTHER
    public var bestEarpieceSizeLeft: EarpieceSize = .NOT_DETERMINED
    public var bestEarpieceSizeRight: EarpieceSize = .NOT_DETERMINED

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_RET_EXT_PARAM,
            type: .WEARING_STATUS_DETECTOR
        ),
        fittingResultLeft: EarpieceFittingDetectionResult = .GOOD,
        fittingResultRight: EarpieceFittingDetectionResult = .GOOD,
        bestEarpieceSeriesLeft: EarpieceSeries = .OTHER,
        bestEarpieceSeriesRight: EarpieceSeries = .OTHER,
        bestEarpieceSizeLeft: EarpieceSize = .NOT_DETERMINED,
        bestEarpieceSizeRight: EarpieceSize = .NOT_DETERMINED
    ) {
        self.base = base
        self.fittingResultLeft = fittingResultLeft
        self.fittingResultRight = fittingResultRight
        self.bestEarpieceSeriesLeft = bestEarpieceSeriesLeft
        self.bestEarpieceSeriesRight = bestEarpieceSeriesRight
        self.bestEarpieceSizeLeft = bestEarpieceSizeLeft
        self.bestEarpieceSizeRight = bestEarpieceSizeRight
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(fittingResultLeft.rawValue)
        writer.writeUInt8(fittingResultRight.rawValue)
        writer.writeUInt8(bestEarpieceSeriesLeft.rawValue)
        writer.writeUInt8(bestEarpieceSeriesRight.rawValue)
        writer.writeUInt8(bestEarpieceSizeLeft.rawValue)
        writer.writeUInt8(bestEarpieceSizeRight.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let fittingResultLeft = EarpieceFittingDetectionResult(rawValue: try reader.readUInt8()) ?? .GOOD
        let fittingResultRight = EarpieceFittingDetectionResult(rawValue: try reader.readUInt8()) ?? .GOOD
        let bestEarpieceSeriesLeft = EarpieceSeries(rawValue: try reader.readUInt8()) ?? .OTHER
        let bestEarpieceSeriesRight = EarpieceSeries(rawValue: try reader.readUInt8()) ?? .OTHER
        let bestEarpieceSizeLeft = EarpieceSize(rawValue: try reader.readUInt8()) ?? .NOT_DETERMINED
        let bestEarpieceSizeRight = EarpieceSize(rawValue: try reader.readUInt8()) ?? .NOT_DETERMINED
        return Self(
            base: base,
            fittingResultLeft: fittingResultLeft,
            fittingResultRight: fittingResultRight,
            bestEarpieceSeriesLeft: bestEarpieceSeriesLeft,
            bestEarpieceSeriesRight: bestEarpieceSeriesRight,
            bestEarpieceSizeLeft: bestEarpieceSizeLeft,
            bestEarpieceSizeRight: bestEarpieceSizeRight
        )
    }
}

// MARK: SystemExtParamSmartTalkingMode2

/// SMART_TALKING_MODE_TYPE2 extended param.
public struct SystemExtParamSmartTalkingMode2: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_SET_EXT_PARAM,
        type: .SMART_TALKING_MODE_TYPE2
    )
    public var detectSensitivity: DetectSensitivity = .AUTO
    public var modeOffTime: ModeOutTime = .FAST

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_SET_EXT_PARAM,
            type: .SMART_TALKING_MODE_TYPE2
        ),
        detectSensitivity: DetectSensitivity = .AUTO,
        modeOffTime: ModeOutTime = .FAST
    ) {
        self.base = base
        self.detectSensitivity = detectSensitivity
        self.modeOffTime = modeOffTime
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(detectSensitivity.rawValue)
        writer.writeUInt8(modeOffTime.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let detectSensitivity = DetectSensitivity(rawValue: try reader.readUInt8()) ?? .AUTO
        let modeOffTime = ModeOutTime(rawValue: try reader.readUInt8()) ?? .FAST
        return Self(base: base, detectSensitivity: detectSensitivity, modeOffTime: modeOffTime)
    }
}

// MARK: SystemExtParamAssignableSettingsWithLimit (EXTERN)

/// ASSIGNABLE_SETTINGS_WITH_LIMITATION extended param. Uses MDRArray<AssignableSettingsPreset>.
public struct SystemExtParamAssignableSettingsWithLimit: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_RET_EXT_PARAM,
        type: .ASSIGNABLE_SETTINGS_WITH_LIMITATION
    )
    public var presets: MDRArray<AssignableSettingsPreset> = MDRArray()

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_RET_EXT_PARAM,
            type: .ASSIGNABLE_SETTINGS_WITH_LIMITATION
        ),
        presets: MDRArray<AssignableSettingsPreset> = MDRArray()
    ) {
        self.base = base
        self.presets = presets
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        presets.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let presets = try MDRArray<AssignableSettingsPreset>.read(from: &reader)
        return Self(base: base, presets: presets)
    }
}

// MARK: SystemSetExtParamCallSettings

/// CALL_SETTINGS (SET EXT variant).
public struct SystemSetExtParamCallSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_SET_EXT_PARAM,
        type: .CALL_SETTINGS
    )
    public var testSoundControl: CallSettingsTestSoundControl = .START

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_SET_EXT_PARAM,
            type: .CALL_SETTINGS
        ),
        testSoundControl: CallSettingsTestSoundControl = .START
    ) {
        self.base = base
        self.testSoundControl = testSoundControl
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(testSoundControl.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let testSoundControl = CallSettingsTestSoundControl(rawValue: try reader.readUInt8()) ?? .START
        return Self(base: base, testSoundControl: testSoundControl)
    }
}

// MARK: SystemNotifyExtParamCallSettings

/// CALL_SETTINGS (NTFY EXT variant).
public struct SystemNotifyExtParamCallSettings: Equatable, Sendable, MDRSerializable {
    public var base: SystemExtBase = SystemExtBase(
        command: .SYSTEM_NTFY_EXT_PARAM,
        type: .CALL_SETTINGS
    )
    public var testSoundControlAck: CallSettingsTestSoundControlAck = .ACK

    public init(
        base: SystemExtBase = SystemExtBase(
            command: .SYSTEM_NTFY_EXT_PARAM,
            type: .CALL_SETTINGS
        ),
        testSoundControlAck: CallSettingsTestSoundControlAck = .ACK
    ) {
        self.base = base
        self.testSoundControlAck = testSoundControlAck
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(testSoundControlAck.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try SystemExtBase.deserialize(from: &reader)
        let testSoundControlAck = CallSettingsTestSoundControlAck(rawValue: try reader.readUInt8()) ?? .ACK
        return Self(base: base, testSoundControlAck: testSoundControlAck)
    }
}
