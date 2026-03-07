import Foundation

// MARK: - Power payload structs (from ProtocolV2T1.hpp)

// PowerGetStatus - trivial: Command + PowerInquiredType
public struct PowerGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_GET_STATUS
    public var type: PowerInquiredType

    public init(command: T1Command = .POWER_GET_STATUS, type: PowerInquiredType = .BATTERY) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .BATTERY
        return Self(command: command, type: type)
    }
}

// PowerBatteryStatus - sub-struct used in Power payloads (not a command itself)
public struct PowerBatteryStatus: Equatable, Sendable, MDRReadWritable {
    public var batteryLevel: UInt8 = 0
    public var chargingStatus: BatteryChargingStatus = .UNKNOWN

    public init(batteryLevel: UInt8 = 0, chargingStatus: BatteryChargingStatus = .UNKNOWN) {
        self.batteryLevel = batteryLevel
        self.chargingStatus = chargingStatus
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let batteryLevel = try reader.readUInt8()
        let chargingStatus = BatteryChargingStatus(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        return Self(batteryLevel: batteryLevel, chargingStatus: chargingStatus)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(batteryLevel)
        writer.writeUInt8(chargingStatus.rawValue)
    }
}

// PowerLeftRightBatteryStatus - sub-struct
public struct PowerLeftRightBatteryStatus: Equatable, Sendable, MDRReadWritable {
    public var leftBatteryLevel: UInt8 = 0
    public var leftChargingStatus: BatteryChargingStatus = .UNKNOWN
    public var rightBatteryLevel: UInt8 = 0
    public var rightChargingStatus: BatteryChargingStatus = .UNKNOWN

    public init(
        leftBatteryLevel: UInt8 = 0, leftChargingStatus: BatteryChargingStatus = .UNKNOWN,
        rightBatteryLevel: UInt8 = 0, rightChargingStatus: BatteryChargingStatus = .UNKNOWN
    ) {
        self.leftBatteryLevel = leftBatteryLevel
        self.leftChargingStatus = leftChargingStatus
        self.rightBatteryLevel = rightBatteryLevel
        self.rightChargingStatus = rightChargingStatus
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let leftBatteryLevel = try reader.readUInt8()
        let leftChargingStatus = BatteryChargingStatus(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let rightBatteryLevel = try reader.readUInt8()
        let rightChargingStatus = BatteryChargingStatus(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        return Self(leftBatteryLevel: leftBatteryLevel, leftChargingStatus: leftChargingStatus,
                    rightBatteryLevel: rightBatteryLevel, rightChargingStatus: rightChargingStatus)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(leftBatteryLevel)
        writer.writeUInt8(leftChargingStatus.rawValue)
        writer.writeUInt8(rightBatteryLevel)
        writer.writeUInt8(rightChargingStatus.rawValue)
    }
}

// PowerBatteryThresholdStatus - sub-struct
public struct PowerBatteryThresholdStatus: Equatable, Sendable, MDRReadWritable {
    public var batteryStatus: PowerBatteryStatus = PowerBatteryStatus()
    public var batteryThreshold: UInt8 = 0

    public init(batteryStatus: PowerBatteryStatus = PowerBatteryStatus(), batteryThreshold: UInt8 = 0) {
        self.batteryStatus = batteryStatus
        self.batteryThreshold = batteryThreshold
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let batteryStatus = try PowerBatteryStatus.read(from: &reader)
        let batteryThreshold = try reader.readUInt8()
        return Self(batteryStatus: batteryStatus, batteryThreshold: batteryThreshold)
    }

    public func write(to writer: inout DataWriter) {
        batteryStatus.write(to: &writer)
        writer.writeUInt8(batteryThreshold)
    }
}

// PowerRetStatusBattery - BATTERY
public struct PowerRetStatusBattery: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_RET_STATUS
    public var type: PowerInquiredType = .BATTERY
    public var batteryStatus: PowerBatteryStatus = PowerBatteryStatus()

    public init(
        command: T1Command = .POWER_RET_STATUS,
        type: PowerInquiredType = .BATTERY,
        batteryStatus: PowerBatteryStatus = PowerBatteryStatus()
    ) {
        self.command = command
        self.type = type
        self.batteryStatus = batteryStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        batteryStatus.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .BATTERY
        let batteryStatus = try PowerBatteryStatus.read(from: &reader)
        return Self(command: command, type: type, batteryStatus: batteryStatus)
    }
}

// PowerRetStatusLeftRightBattery - LEFT_RIGHT_BATTERY
public struct PowerRetStatusLeftRightBattery: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_RET_STATUS
    public var type: PowerInquiredType = .LEFT_RIGHT_BATTERY
    public var batteryStatus: PowerLeftRightBatteryStatus = PowerLeftRightBatteryStatus()

    public init(
        command: T1Command = .POWER_RET_STATUS,
        type: PowerInquiredType = .LEFT_RIGHT_BATTERY,
        batteryStatus: PowerLeftRightBatteryStatus = PowerLeftRightBatteryStatus()
    ) {
        self.command = command
        self.type = type
        self.batteryStatus = batteryStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        batteryStatus.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .LEFT_RIGHT_BATTERY
        let batteryStatus = try PowerLeftRightBatteryStatus.read(from: &reader)
        return Self(command: command, type: type, batteryStatus: batteryStatus)
    }
}

// PowerRetStatusCradleBattery - CRADLE_BATTERY
public struct PowerRetStatusCradleBattery: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_RET_STATUS
    public var type: PowerInquiredType = .CRADLE_BATTERY
    public var batteryStatus: PowerBatteryStatus = PowerBatteryStatus()

    public init(
        command: T1Command = .POWER_RET_STATUS,
        type: PowerInquiredType = .CRADLE_BATTERY,
        batteryStatus: PowerBatteryStatus = PowerBatteryStatus()
    ) {
        self.command = command
        self.type = type
        self.batteryStatus = batteryStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        batteryStatus.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .CRADLE_BATTERY
        let batteryStatus = try PowerBatteryStatus.read(from: &reader)
        return Self(command: command, type: type, batteryStatus: batteryStatus)
    }
}

// PowerRetStatusBatteryThreshold - BATTERY_WITH_THRESHOLD
public struct PowerRetStatusBatteryThreshold: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_RET_STATUS
    public var type: PowerInquiredType = .BATTERY_WITH_THRESHOLD
    public var batteryStatus: PowerBatteryThresholdStatus = PowerBatteryThresholdStatus()

    public init(
        command: T1Command = .POWER_RET_STATUS,
        type: PowerInquiredType = .BATTERY_WITH_THRESHOLD,
        batteryStatus: PowerBatteryThresholdStatus = PowerBatteryThresholdStatus()
    ) {
        self.command = command
        self.type = type
        self.batteryStatus = batteryStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        batteryStatus.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .BATTERY_WITH_THRESHOLD
        let batteryStatus = try PowerBatteryThresholdStatus.read(from: &reader)
        return Self(command: command, type: type, batteryStatus: batteryStatus)
    }
}

// PowerRetStatusLeftRightBatteryThreshold - LR_BATTERY_WITH_THRESHOLD
public struct PowerRetStatusLeftRightBatteryThreshold: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_RET_STATUS
    public var type: PowerInquiredType = .LR_BATTERY_WITH_THRESHOLD
    public var batteryStatus: PowerLeftRightBatteryStatus = PowerLeftRightBatteryStatus()
    public var leftBatteryThreshold: UInt8 = 0
    public var rightBatteryThreshold: UInt8 = 0

    public init(
        command: T1Command = .POWER_RET_STATUS,
        type: PowerInquiredType = .LR_BATTERY_WITH_THRESHOLD,
        batteryStatus: PowerLeftRightBatteryStatus = PowerLeftRightBatteryStatus(),
        leftBatteryThreshold: UInt8 = 0,
        rightBatteryThreshold: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.batteryStatus = batteryStatus
        self.leftBatteryThreshold = leftBatteryThreshold
        self.rightBatteryThreshold = rightBatteryThreshold
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        batteryStatus.write(to: &writer)
        writer.writeUInt8(leftBatteryThreshold)
        writer.writeUInt8(rightBatteryThreshold)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .LR_BATTERY_WITH_THRESHOLD
        let batteryStatus = try PowerLeftRightBatteryStatus.read(from: &reader)
        let leftBatteryThreshold = try reader.readUInt8()
        let rightBatteryThreshold = try reader.readUInt8()
        return Self(command: command, type: type, batteryStatus: batteryStatus,
                    leftBatteryThreshold: leftBatteryThreshold, rightBatteryThreshold: rightBatteryThreshold)
    }
}

// PowerRetStatusCradleBatteryThreshold - CRADLE_BATTERY_WITH_THRESHOLD
public struct PowerRetStatusCradleBatteryThreshold: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_RET_STATUS
    public var type: PowerInquiredType = .CRADLE_BATTERY_WITH_THRESHOLD
    public var batteryStatus: PowerBatteryThresholdStatus = PowerBatteryThresholdStatus()

    public init(
        command: T1Command = .POWER_RET_STATUS,
        type: PowerInquiredType = .CRADLE_BATTERY_WITH_THRESHOLD,
        batteryStatus: PowerBatteryThresholdStatus = PowerBatteryThresholdStatus()
    ) {
        self.command = command
        self.type = type
        self.batteryStatus = batteryStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        batteryStatus.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .CRADLE_BATTERY_WITH_THRESHOLD
        let batteryStatus = try PowerBatteryThresholdStatus.read(from: &reader)
        return Self(command: command, type: type, batteryStatus: batteryStatus)
    }
}

// PowerSetStatusPowerOff - POWER_OFF
public struct PowerSetStatusPowerOff: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_SET_STATUS
    public var type: PowerInquiredType = .POWER_OFF
    public var powerOffSettingValue: PowerOffSettingValue = .USER_POWER_OFF

    public init(
        command: T1Command = .POWER_SET_STATUS,
        type: PowerInquiredType = .POWER_OFF,
        powerOffSettingValue: PowerOffSettingValue = .USER_POWER_OFF
    ) {
        self.command = command
        self.type = type
        self.powerOffSettingValue = powerOffSettingValue
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(powerOffSettingValue.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .POWER_OFF
        let powerOffSettingValue = PowerOffSettingValue(rawValue: try reader.readUInt8()) ?? .USER_POWER_OFF
        return Self(command: command, type: type, powerOffSettingValue: powerOffSettingValue)
    }
}

// PowerGetParam
public struct PowerGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_GET_PARAM
    public var type: PowerInquiredType = .AUTO_POWER_OFF

    public init(command: T1Command = .POWER_GET_PARAM, type: PowerInquiredType = .AUTO_POWER_OFF) {
        self.command = command
        self.type = type
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .AUTO_POWER_OFF
        return Self(command: command, type: type)
    }
}

// PowerParamAutoPowerOff - AUTO_POWER_OFF
public struct PowerParamAutoPowerOff: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_SET_PARAM
    public var type: PowerInquiredType = .AUTO_POWER_OFF
    public var currentPowerOffElements: AutoPowerOffElements = .POWER_OFF_IN_5_MIN
    public var lastSelectPowerOffElements: AutoPowerOffElements = .POWER_OFF_IN_5_MIN

    public init(
        command: T1Command = .POWER_SET_PARAM,
        type: PowerInquiredType = .AUTO_POWER_OFF,
        currentPowerOffElements: AutoPowerOffElements = .POWER_OFF_IN_5_MIN,
        lastSelectPowerOffElements: AutoPowerOffElements = .POWER_OFF_IN_5_MIN
    ) {
        self.command = command
        self.type = type
        self.currentPowerOffElements = currentPowerOffElements
        self.lastSelectPowerOffElements = lastSelectPowerOffElements
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(currentPowerOffElements.rawValue)
        writer.writeUInt8(lastSelectPowerOffElements.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .AUTO_POWER_OFF
        let currentPowerOffElements = AutoPowerOffElements(rawValue: try reader.readUInt8()) ?? .POWER_OFF_IN_5_MIN
        let lastSelectPowerOffElements = AutoPowerOffElements(rawValue: try reader.readUInt8()) ?? .POWER_OFF_IN_5_MIN
        return Self(command: command, type: type,
                    currentPowerOffElements: currentPowerOffElements,
                    lastSelectPowerOffElements: lastSelectPowerOffElements)
    }
}

// PowerParamAutoPowerOffWithWearingDetection - AUTO_POWER_OFF_WEARING_DETECTION
public struct PowerParamAutoPowerOffWithWearingDetection: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_SET_PARAM
    public var type: PowerInquiredType = .AUTO_POWER_OFF_WEARING_DETECTION
    public var currentPowerOffElements: AutoPowerOffWearingDetectionElements = .POWER_OFF_IN_5_MIN
    public var lastSelectPowerOffElements: AutoPowerOffWearingDetectionElements = .POWER_OFF_IN_5_MIN

    public init(
        command: T1Command = .POWER_SET_PARAM,
        type: PowerInquiredType = .AUTO_POWER_OFF_WEARING_DETECTION,
        currentPowerOffElements: AutoPowerOffWearingDetectionElements = .POWER_OFF_IN_5_MIN,
        lastSelectPowerOffElements: AutoPowerOffWearingDetectionElements = .POWER_OFF_IN_5_MIN
    ) {
        self.command = command
        self.type = type
        self.currentPowerOffElements = currentPowerOffElements
        self.lastSelectPowerOffElements = lastSelectPowerOffElements
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(currentPowerOffElements.rawValue)
        writer.writeUInt8(lastSelectPowerOffElements.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .AUTO_POWER_OFF_WEARING_DETECTION
        let currentPowerOffElements = AutoPowerOffWearingDetectionElements(rawValue: try reader.readUInt8()) ?? .POWER_OFF_IN_5_MIN
        let lastSelectPowerOffElements = AutoPowerOffWearingDetectionElements(rawValue: try reader.readUInt8()) ?? .POWER_OFF_IN_5_MIN
        return Self(command: command, type: type,
                    currentPowerOffElements: currentPowerOffElements,
                    lastSelectPowerOffElements: lastSelectPowerOffElements)
    }
}

// PowerParamSettingOnOff - POWER_SAVE_MODE, CARING_CHARGE, BT_STANDBY, STAMINA, etc.
public struct PowerParamSettingOnOff: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_GET_PARAM
    public var type: PowerInquiredType = .POWER_SAVE_MODE
    public var onOffSetting: MessageMdrV2OnOffSettingValue = .OFF

    public init(
        command: T1Command = .POWER_GET_PARAM,
        type: PowerInquiredType = .POWER_SAVE_MODE,
        onOffSetting: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.onOffSetting = onOffSetting
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(onOffSetting.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .POWER_SAVE_MODE
        let onOffSetting = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, onOffSetting: onOffSetting)
    }
}

// PowerParamBatterySafeMode - BATTERY_SAFE_MODE
public struct PowerParamBatterySafeMode: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .POWER_GET_PARAM
    public var type: PowerInquiredType = .BATTERY_SAFE_MODE
    public var onOffSettingValue: MessageMdrV2OnOffSettingValue = .OFF
    public var effectStatus: MessageMdrV2OnOffSettingValue = .OFF

    public init(
        command: T1Command = .POWER_GET_PARAM,
        type: PowerInquiredType = .BATTERY_SAFE_MODE,
        onOffSettingValue: MessageMdrV2OnOffSettingValue = .OFF,
        effectStatus: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.onOffSettingValue = onOffSettingValue
        self.effectStatus = effectStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(onOffSettingValue.rawValue)
        writer.writeUInt8(effectStatus.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PowerInquiredType(rawValue: try reader.readUInt8()) ?? .BATTERY_SAFE_MODE
        let onOffSettingValue = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        let effectStatus = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, onOffSettingValue: onOffSettingValue, effectStatus: effectStatus)
    }
}
