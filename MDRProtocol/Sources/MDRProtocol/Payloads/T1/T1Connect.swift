import Foundation

// MARK: - Connect payloads from ProtocolV2T1.hpp

// MARK: ConnectGetProtocolInfo

public struct ConnectGetProtocolInfo: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_GET_PROTOCOL_INFO
    public var inquiredType: ConnectInquiredType = .FIXED_VALUE

    public init(
        command: T1Command = .CONNECT_GET_PROTOCOL_INFO,
        inquiredType: ConnectInquiredType = .FIXED_VALUE
    ) {
        self.command = command
        self.inquiredType = inquiredType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        return Self(command: command, inquiredType: inquiredType)
    }
}

// MARK: ConnectRetProtocolInfo

public struct ConnectRetProtocolInfo: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_RET_PROTOCOL_INFO
    public var inquiredType: ConnectInquiredType = .FIXED_VALUE
    public var protocolVersion: Int32BE = Int32BE()
    public var supportTable1Value: MessageMdrV2EnableDisable = .ENABLE
    public var supportTable2Value: MessageMdrV2EnableDisable = .ENABLE

    public init(
        command: T1Command = .CONNECT_RET_PROTOCOL_INFO,
        inquiredType: ConnectInquiredType = .FIXED_VALUE,
        protocolVersion: Int32BE = Int32BE(),
        supportTable1Value: MessageMdrV2EnableDisable = .ENABLE,
        supportTable2Value: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.protocolVersion = protocolVersion
        self.supportTable1Value = supportTable1Value
        self.supportTable2Value = supportTable2Value
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        writer.writeInt32BE(protocolVersion)
        writer.writeUInt8(supportTable1Value.rawValue)
        writer.writeUInt8(supportTable2Value.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        let protocolVersion = try reader.readInt32BE()
        let supportTable1Value = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let supportTable2Value = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(
            command: command,
            inquiredType: inquiredType,
            protocolVersion: protocolVersion,
            supportTable1Value: supportTable1Value,
            supportTable2Value: supportTable2Value
        )
    }
}

// MARK: ConnectGetCapabilityInfo

public struct ConnectGetCapabilityInfo: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_GET_CAPABILITY_INFO
    public var inquiredType: ConnectInquiredType = .FIXED_VALUE

    public init(
        command: T1Command = .CONNECT_GET_CAPABILITY_INFO,
        inquiredType: ConnectInquiredType = .FIXED_VALUE
    ) {
        self.command = command
        self.inquiredType = inquiredType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        return Self(command: command, inquiredType: inquiredType)
    }
}

// MARK: ConnectGetDeviceInfo

public struct ConnectGetDeviceInfo: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_GET_DEVICE_INFO
    public var deviceInfoType: DeviceInfoType = .MODEL_NAME

    public init(
        command: T1Command = .CONNECT_GET_DEVICE_INFO,
        deviceInfoType: DeviceInfoType = .MODEL_NAME
    ) {
        self.command = command
        self.deviceInfoType = deviceInfoType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(deviceInfoType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let deviceInfoType = DeviceInfoType(rawValue: try reader.readUInt8()) ?? .MODEL_NAME
        return Self(command: command, deviceInfoType: deviceInfoType)
    }
}

// MARK: ConnectRetCapabilityInfo (EXTERN)

public struct ConnectRetCapabilityInfo: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_RET_CAPABILITY_INFO
    public var inquiredType: ConnectInquiredType = .FIXED_VALUE
    public var capabilityCounter: UInt8 = 0
    public var uniqueID: PrefixedString = PrefixedString()

    public init(
        command: T1Command = .CONNECT_RET_CAPABILITY_INFO,
        inquiredType: ConnectInquiredType = .FIXED_VALUE,
        capabilityCounter: UInt8 = 0,
        uniqueID: PrefixedString = PrefixedString()
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.capabilityCounter = capabilityCounter
        self.uniqueID = uniqueID
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        writer.writeUInt8(capabilityCounter)
        uniqueID.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        let capabilityCounter = try reader.readUInt8()
        let uniqueID = try PrefixedString.read(from: &reader)
        return Self(
            command: command,
            inquiredType: inquiredType,
            capabilityCounter: capabilityCounter,
            uniqueID: uniqueID
        )
    }
}

// MARK: ConnectRetDeviceInfoBase

public struct ConnectRetDeviceInfoBase: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_RET_DEVICE_INFO
    public var type: DeviceInfoType = .MODEL_NAME

    public init(
        command: T1Command = .CONNECT_RET_DEVICE_INFO,
        type: DeviceInfoType = .MODEL_NAME
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
        let type = DeviceInfoType(rawValue: try reader.readUInt8()) ?? .MODEL_NAME
        return Self(command: command, type: type)
    }
}

// MARK: ConnectRetDeviceInfoModelName (EXTERN)

public struct ConnectRetDeviceInfoModelName: Equatable, Sendable, MDRSerializable {
    public var base: ConnectRetDeviceInfoBase = ConnectRetDeviceInfoBase(
        command: .CONNECT_RET_DEVICE_INFO,
        type: .MODEL_NAME
    )
    public var value: PrefixedString = PrefixedString()

    public init(
        base: ConnectRetDeviceInfoBase = ConnectRetDeviceInfoBase(
            command: .CONNECT_RET_DEVICE_INFO,
            type: .MODEL_NAME
        ),
        value: PrefixedString = PrefixedString()
    ) {
        self.base = base
        self.value = value
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        value.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try ConnectRetDeviceInfoBase.deserialize(from: &reader)
        let value = try PrefixedString.read(from: &reader)
        return Self(base: base, value: value)
    }
}

// MARK: ConnectRetDeviceInfoFwVersion (EXTERN)

public struct ConnectRetDeviceInfoFwVersion: Equatable, Sendable, MDRSerializable {
    public var base: ConnectRetDeviceInfoBase = ConnectRetDeviceInfoBase(
        command: .CONNECT_RET_DEVICE_INFO,
        type: .FW_VERSION
    )
    public var value: PrefixedString = PrefixedString()

    public init(
        base: ConnectRetDeviceInfoBase = ConnectRetDeviceInfoBase(
            command: .CONNECT_RET_DEVICE_INFO,
            type: .FW_VERSION
        ),
        value: PrefixedString = PrefixedString()
    ) {
        self.base = base
        self.value = value
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        value.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try ConnectRetDeviceInfoBase.deserialize(from: &reader)
        let value = try PrefixedString.read(from: &reader)
        return Self(base: base, value: value)
    }
}

// MARK: ConnectRetDeviceInfoSeriesAndColor (EXTERN)

public struct ConnectRetDeviceInfoSeriesAndColor: Equatable, Sendable, MDRSerializable {
    public var base: ConnectRetDeviceInfoBase = ConnectRetDeviceInfoBase(
        command: .CONNECT_RET_DEVICE_INFO,
        type: .SERIES_AND_COLOR_INFO
    )
    public var series: ModelSeriesType = .NO_SERIES
    public var color: ModelColor = .DEFAULT

    public init(
        base: ConnectRetDeviceInfoBase = ConnectRetDeviceInfoBase(
            command: .CONNECT_RET_DEVICE_INFO,
            type: .SERIES_AND_COLOR_INFO
        ),
        series: ModelSeriesType = .NO_SERIES,
        color: ModelColor = .DEFAULT
    ) {
        self.base = base
        self.series = series
        self.color = color
    }

    public func serialize(to writer: inout DataWriter) {
        base.serialize(to: &writer)
        writer.writeUInt8(series.rawValue)
        writer.writeUInt8(color.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let base = try ConnectRetDeviceInfoBase.deserialize(from: &reader)
        let series = ModelSeriesType(rawValue: try reader.readUInt8()) ?? .NO_SERIES
        let color = ModelColor(rawValue: try reader.readUInt8()) ?? .DEFAULT
        return Self(base: base, series: series, color: color)
    }
}

// MARK: ConnectGetSupportFunction

public struct ConnectGetSupportFunction: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_GET_SUPPORT_FUNCTION
    public var inquiredType: ConnectInquiredType = .FIXED_VALUE

    public init(
        command: T1Command = .CONNECT_GET_SUPPORT_FUNCTION,
        inquiredType: ConnectInquiredType = .FIXED_VALUE
    ) {
        self.command = command
        self.inquiredType = inquiredType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        return Self(command: command, inquiredType: inquiredType)
    }
}

// MARK: SupportFunctionEntry

/// Represents a single support function entry from MDRPodArray<MessageMdrV2SupportFunction>.
/// In C++, MessageMdrV2SupportFunction is a 2-byte struct: a union of Table1/Table2 function type
/// (1 byte) + priority (1 byte).
public struct SupportFunctionEntry: Equatable, Sendable, MDRReadWritable {
    public var rawFunction: UInt8 = 0
    public var priority: UInt8 = 0

    public init(rawFunction: UInt8 = 0, priority: UInt8 = 0) {
        self.rawFunction = rawFunction
        self.priority = priority
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let rawFunction = try reader.readUInt8()
        let priority = try reader.readUInt8()
        return Self(rawFunction: rawFunction, priority: priority)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(rawFunction)
        writer.writeUInt8(priority)
    }
}

// MARK: ConnectRetSupportFunction (EXTERN)

public struct ConnectRetSupportFunction: Equatable, Sendable, MDRSerializable {
    public var command: T1Command = .CONNECT_RET_SUPPORT_FUNCTION
    public var inquiredType: ConnectInquiredType = .FIXED_VALUE
    public var supportFunctions: [SupportFunctionEntry] = []

    public init(
        command: T1Command = .CONNECT_RET_SUPPORT_FUNCTION,
        inquiredType: ConnectInquiredType = .FIXED_VALUE,
        supportFunctions: [SupportFunctionEntry] = []
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.supportFunctions = supportFunctions
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        precondition(supportFunctions.count <= 255, "SupportFunctions array too long")
        writer.writeUInt8(UInt8(supportFunctions.count))
        for entry in supportFunctions {
            entry.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T1Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = ConnectInquiredType(rawValue: try reader.readUInt8()) ?? .FIXED_VALUE
        let count = try reader.readUInt8()
        var supportFunctions: [SupportFunctionEntry] = []
        supportFunctions.reserveCapacity(Int(count))
        for _ in 0..<count {
            let entry = try SupportFunctionEntry.read(from: &reader)
            supportFunctions.append(entry)
        }
        return Self(
            command: command,
            inquiredType: inquiredType,
            supportFunctions: supportFunctions
        )
    }
}
