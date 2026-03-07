import Foundation

// MARK: - T2 SafeListening payloads from ProtocolV2T2.hpp

// MARK: - Sub-structs (MDRReadWritable)

// MARK: SafeListeningData

/// Base safe listening data: targetType(1) + timestamp(4) + rtcRC(2) + viewTime(1) + soundPressure(4) = 12 bytes.
public struct SafeListeningData: Equatable, Sendable, MDRReadWritable {
    public var targetType: SafeListeningTargetType
    public var timestamp: Int32BE
    public var rtcRC: Int16BE
    public var viewTime: UInt8
    public var soundPressure: Int32BE

    public init(
        targetType: SafeListeningTargetType = .HBS,
        timestamp: Int32BE = Int32BE(),
        rtcRC: Int16BE = Int16BE(),
        viewTime: UInt8 = 0,
        soundPressure: Int32BE = Int32BE()
    ) {
        self.targetType = targetType
        self.timestamp = timestamp
        self.rtcRC = rtcRC
        self.viewTime = viewTime
        self.soundPressure = soundPressure
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let targetType = SafeListeningTargetType(rawValue: try reader.readUInt8()) ?? .HBS
        let timestamp = try reader.readInt32BE()
        let rtcRC = try reader.readInt16BE()
        let viewTime = try reader.readUInt8()
        let soundPressure = try reader.readInt32BE()
        return Self(
            targetType: targetType,
            timestamp: timestamp,
            rtcRC: rtcRC,
            viewTime: viewTime,
            soundPressure: soundPressure
        )
    }

    public func write(to writer: inout DataWriter) {
        writer.writeUInt8(targetType.rawValue)
        writer.writeInt32BE(timestamp)
        writer.writeInt16BE(rtcRC)
        writer.writeUInt8(viewTime)
        writer.writeInt32BE(soundPressure)
    }
}

// MARK: SafeListeningData1

/// SafeListeningData1 wraps SafeListeningData (same 12 bytes).
public struct SafeListeningData1: Equatable, Sendable, MDRReadWritable {
    public var data: SafeListeningData

    public init(data: SafeListeningData = SafeListeningData()) {
        self.data = data
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let data = try SafeListeningData.read(from: &reader)
        return Self(data: data)
    }

    public func write(to writer: inout DataWriter) {
        data.write(to: &writer)
    }
}

// MARK: SafeListeningData2

/// SafeListeningData2 is SafeListeningData(12 bytes) + ambientTime(1 byte) = 13 bytes.
public struct SafeListeningData2: Equatable, Sendable, MDRReadWritable {
    public var data: SafeListeningData
    public var ambientTime: UInt8

    public init(
        data: SafeListeningData = SafeListeningData(),
        ambientTime: UInt8 = 0
    ) {
        self.data = data
        self.ambientTime = ambientTime
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let data = try SafeListeningData.read(from: &reader)
        let ambientTime = try reader.readUInt8()
        return Self(data: data, ambientTime: ambientTime)
    }

    public func write(to writer: inout DataWriter) {
        data.write(to: &writer)
        writer.writeUInt8(ambientTime)
    }
}

// MARK: SafeListeningStatus

/// SafeListening status sub-struct: timestamp(4) + rtcRC(2) = 6 bytes.
public struct SafeListeningStatus: Equatable, Sendable, MDRReadWritable {
    public var timestamp: Int32BE
    public var rtcRC: Int16BE

    public init(
        timestamp: Int32BE = Int32BE(),
        rtcRC: Int16BE = Int16BE()
    ) {
        self.timestamp = timestamp
        self.rtcRC = rtcRC
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let timestamp = try reader.readInt32BE()
        let rtcRC = try reader.readInt16BE()
        return Self(timestamp: timestamp, rtcRC: rtcRC)
    }

    public func write(to writer: inout DataWriter) {
        writer.writeInt32BE(timestamp)
        writer.writeInt16BE(rtcRC)
    }
}

// MARK: - Main structs

// MARK: SafeListeningGetCapability

public struct SafeListeningGetCapability: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_GET_CAPABILITY
    public var type: SafeListeningInquiredType

    public init(
        command: T2Command = .SAFE_LISTENING_GET_CAPABILITY,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
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
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        return Self(command: command, type: type)
    }
}

// MARK: SafeListeningRetCapability

public struct SafeListeningRetCapability: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_CAPABILITY
    public var inquiredType: SafeListeningInquiredType
    public var roundBase: UInt8
    public var timestampBase: Int32BE
    public var minimumInterval: UInt8
    public var logCapacity: UInt8

    public init(
        command: T2Command = .SAFE_LISTENING_RET_CAPABILITY,
        inquiredType: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        roundBase: UInt8 = 0,
        timestampBase: Int32BE = Int32BE(),
        minimumInterval: UInt8 = 0,
        logCapacity: UInt8 = 0
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.roundBase = roundBase
        self.timestampBase = timestampBase
        self.minimumInterval = minimumInterval
        self.logCapacity = logCapacity
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        writer.writeUInt8(roundBase)
        writer.writeInt32BE(timestampBase)
        writer.writeUInt8(minimumInterval)
        writer.writeUInt8(logCapacity)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let roundBase = try reader.readUInt8()
        let timestampBase = try reader.readInt32BE()
        let minimumInterval = try reader.readUInt8()
        let logCapacity = try reader.readUInt8()
        return Self(
            command: command,
            inquiredType: inquiredType,
            roundBase: roundBase,
            timestampBase: timestampBase,
            minimumInterval: minimumInterval,
            logCapacity: logCapacity
        )
    }
}

// MARK: SafeListeningGetStatus

public struct SafeListeningGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_GET_STATUS
    public var inquiredType: SafeListeningInquiredType

    public init(
        command: T2Command = .SAFE_LISTENING_GET_STATUS,
        inquiredType: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    ) {
        self.command = command
        self.inquiredType = inquiredType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        return Self(command: command, inquiredType: inquiredType)
    }
}

// MARK: SafeListeningRetStatusHbs1

public struct SafeListeningRetStatusHbs1: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    public var logDataStatus: SafeListeningLogDataStatus
    public var currentData: SafeListeningData1

    public init(
        command: T2Command = .SAFE_LISTENING_RET_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        logDataStatus: SafeListeningLogDataStatus = .DISCONNECTED,
        currentData: SafeListeningData1 = SafeListeningData1()
    ) {
        self.command = command
        self.type = type
        self.logDataStatus = logDataStatus
        self.currentData = currentData
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatus.rawValue)
        currentData.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let logDataStatus = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let currentData = try SafeListeningData1.read(from: &reader)
        return Self(command: command, type: type, logDataStatus: logDataStatus, currentData: currentData)
    }
}

// MARK: SafeListeningRetStatusHbs2

public struct SafeListeningRetStatusHbs2: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_2
    public var logDataStatus: SafeListeningLogDataStatus
    public var currentData: SafeListeningData2

    public init(
        command: T2Command = .SAFE_LISTENING_RET_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_2,
        logDataStatus: SafeListeningLogDataStatus = .DISCONNECTED,
        currentData: SafeListeningData2 = SafeListeningData2()
    ) {
        self.command = command
        self.type = type
        self.logDataStatus = logDataStatus
        self.currentData = currentData
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatus.rawValue)
        currentData.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_2
        let logDataStatus = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let currentData = try SafeListeningData2.read(from: &reader)
        return Self(command: command, type: type, logDataStatus: logDataStatus, currentData: currentData)
    }
}

// MARK: SafeListeningRetStatusTws1

public struct SafeListeningRetStatusTws1: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_1
    public var logDataStatusLeft: SafeListeningLogDataStatus
    public var logDataStatusRight: SafeListeningLogDataStatus
    public var currentDataLeft: SafeListeningData1
    public var currentDataRight: SafeListeningData1

    public init(
        command: T2Command = .SAFE_LISTENING_RET_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_1,
        logDataStatusLeft: SafeListeningLogDataStatus = .DISCONNECTED,
        logDataStatusRight: SafeListeningLogDataStatus = .DISCONNECTED,
        currentDataLeft: SafeListeningData1 = SafeListeningData1(),
        currentDataRight: SafeListeningData1 = SafeListeningData1()
    ) {
        self.command = command
        self.type = type
        self.logDataStatusLeft = logDataStatusLeft
        self.logDataStatusRight = logDataStatusRight
        self.currentDataLeft = currentDataLeft
        self.currentDataRight = currentDataRight
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatusLeft.rawValue)
        writer.writeUInt8(logDataStatusRight.rawValue)
        currentDataLeft.write(to: &writer)
        currentDataRight.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_TWS_1
        let logDataStatusLeft = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let logDataStatusRight = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let currentDataLeft = try SafeListeningData1.read(from: &reader)
        let currentDataRight = try SafeListeningData1.read(from: &reader)
        return Self(
            command: command,
            type: type,
            logDataStatusLeft: logDataStatusLeft,
            logDataStatusRight: logDataStatusRight,
            currentDataLeft: currentDataLeft,
            currentDataRight: currentDataRight
        )
    }
}

// MARK: SafeListeningRetStatusTws2

public struct SafeListeningRetStatusTws2: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_2
    public var logDataStatusLeft: SafeListeningLogDataStatus
    public var logDataStatusRight: SafeListeningLogDataStatus
    public var currentDataLeft: SafeListeningData2
    public var currentDataRight: SafeListeningData2

    public init(
        command: T2Command = .SAFE_LISTENING_RET_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_2,
        logDataStatusLeft: SafeListeningLogDataStatus = .DISCONNECTED,
        logDataStatusRight: SafeListeningLogDataStatus = .DISCONNECTED,
        currentDataLeft: SafeListeningData2 = SafeListeningData2(),
        currentDataRight: SafeListeningData2 = SafeListeningData2()
    ) {
        self.command = command
        self.type = type
        self.logDataStatusLeft = logDataStatusLeft
        self.logDataStatusRight = logDataStatusRight
        self.currentDataLeft = currentDataLeft
        self.currentDataRight = currentDataRight
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatusLeft.rawValue)
        writer.writeUInt8(logDataStatusRight.rawValue)
        currentDataLeft.write(to: &writer)
        currentDataRight.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_TWS_2
        let logDataStatusLeft = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let logDataStatusRight = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let currentDataLeft = try SafeListeningData2.read(from: &reader)
        let currentDataRight = try SafeListeningData2.read(from: &reader)
        return Self(
            command: command,
            type: type,
            logDataStatusLeft: logDataStatusLeft,
            logDataStatusRight: logDataStatusRight,
            currentDataLeft: currentDataLeft,
            currentDataRight: currentDataRight
        )
    }
}

// MARK: SafeListeningSetStatusHbs

public struct SafeListeningSetStatusHbs: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_SET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    public var logDataStatus: SafeListeningLogDataStatus
    public var status: SafeListeningStatus

    public init(
        command: T2Command = .SAFE_LISTENING_SET_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        logDataStatus: SafeListeningLogDataStatus = .DISCONNECTED,
        status: SafeListeningStatus = SafeListeningStatus()
    ) {
        self.command = command
        self.type = type
        self.logDataStatus = logDataStatus
        self.status = status
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatus.rawValue)
        status.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let logDataStatus = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let status = try SafeListeningStatus.read(from: &reader)
        return Self(command: command, type: type, logDataStatus: logDataStatus, status: status)
    }
}

// MARK: SafeListeningSetStatusTws

public struct SafeListeningSetStatusTws: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_SET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_1
    public var logDataStatusLeft: SafeListeningLogDataStatus
    public var logDataStatusRight: SafeListeningLogDataStatus
    public var statusLeft: SafeListeningStatus
    public var statusRight: SafeListeningStatus

    public init(
        command: T2Command = .SAFE_LISTENING_SET_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_1,
        logDataStatusLeft: SafeListeningLogDataStatus = .DISCONNECTED,
        logDataStatusRight: SafeListeningLogDataStatus = .DISCONNECTED,
        statusLeft: SafeListeningStatus = SafeListeningStatus(),
        statusRight: SafeListeningStatus = SafeListeningStatus()
    ) {
        self.command = command
        self.type = type
        self.logDataStatusLeft = logDataStatusLeft
        self.logDataStatusRight = logDataStatusRight
        self.statusLeft = statusLeft
        self.statusRight = statusRight
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatusLeft.rawValue)
        writer.writeUInt8(logDataStatusRight.rawValue)
        statusLeft.write(to: &writer)
        statusRight.write(to: &writer)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_TWS_1
        let logDataStatusLeft = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let logDataStatusRight = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let statusLeft = try SafeListeningStatus.read(from: &reader)
        let statusRight = try SafeListeningStatus.read(from: &reader)
        return Self(
            command: command,
            type: type,
            logDataStatusLeft: logDataStatusLeft,
            logDataStatusRight: logDataStatusRight,
            statusLeft: statusLeft,
            statusRight: statusRight
        )
    }
}

// MARK: SafeListeningSetStatusSVC

public struct SafeListeningSetStatusSVC: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_SET_STATUS
    public var type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL
    public var whoStandardLevel: SafeListeningWHOStandardLevel

    public init(
        command: T2Command = .SAFE_LISTENING_SET_STATUS,
        type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL,
        whoStandardLevel: SafeListeningWHOStandardLevel = .NORMAL
    ) {
        self.command = command
        self.type = type
        self.whoStandardLevel = whoStandardLevel
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(whoStandardLevel.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_VOLUME_CONTROL
        let whoStandardLevel = SafeListeningWHOStandardLevel(rawValue: try reader.readUInt8()) ?? .NORMAL
        return Self(command: command, type: type, whoStandardLevel: whoStandardLevel)
    }
}

// MARK: SafeListeningNotifyStatusHbs1 (EXTERN)

public struct SafeListeningNotifyStatusHbs1: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    public var logDataStatus: SafeListeningLogDataStatus
    public var data: [SafeListeningData1]

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        logDataStatus: SafeListeningLogDataStatus = .DISCONNECTED,
        data: [SafeListeningData1] = []
    ) {
        self.command = command
        self.type = type
        self.logDataStatus = logDataStatus
        self.data = data
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatus.rawValue)
        precondition(data.count <= 255, "SafeListeningData1 array too long")
        writer.writeUInt8(UInt8(data.count))
        for entry in data {
            entry.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let logDataStatus = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let count = try reader.readUInt8()
        var data: [SafeListeningData1] = []
        data.reserveCapacity(Int(count))
        for _ in 0..<count {
            let entry = try SafeListeningData1.read(from: &reader)
            data.append(entry)
        }
        return Self(command: command, type: type, logDataStatus: logDataStatus, data: data)
    }
}

// MARK: SafeListeningNotifyStatusHbs2 (EXTERN)

public struct SafeListeningNotifyStatusHbs2: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_2
    public var logDataStatus: SafeListeningLogDataStatus
    public var data: [SafeListeningData2]

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_2,
        logDataStatus: SafeListeningLogDataStatus = .DISCONNECTED,
        data: [SafeListeningData2] = []
    ) {
        self.command = command
        self.type = type
        self.logDataStatus = logDataStatus
        self.data = data
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatus.rawValue)
        precondition(data.count <= 255, "SafeListeningData2 array too long")
        writer.writeUInt8(UInt8(data.count))
        for entry in data {
            entry.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_2
        let logDataStatus = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let count = try reader.readUInt8()
        var data: [SafeListeningData2] = []
        data.reserveCapacity(Int(count))
        for _ in 0..<count {
            let entry = try SafeListeningData2.read(from: &reader)
            data.append(entry)
        }
        return Self(command: command, type: type, logDataStatus: logDataStatus, data: data)
    }
}

// MARK: SafeListeningNotifyStatusTws1 (EXTERN)

public struct SafeListeningNotifyStatusTws1: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_1
    public var logDataStatusLeft: SafeListeningLogDataStatus
    public var logDataStatusRight: SafeListeningLogDataStatus
    public var data: [SafeListeningData1]

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_1,
        logDataStatusLeft: SafeListeningLogDataStatus = .DISCONNECTED,
        logDataStatusRight: SafeListeningLogDataStatus = .DISCONNECTED,
        data: [SafeListeningData1] = []
    ) {
        self.command = command
        self.type = type
        self.logDataStatusLeft = logDataStatusLeft
        self.logDataStatusRight = logDataStatusRight
        self.data = data
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatusLeft.rawValue)
        writer.writeUInt8(logDataStatusRight.rawValue)
        precondition(data.count <= 255, "SafeListeningData1 array too long")
        writer.writeUInt8(UInt8(data.count))
        for entry in data {
            entry.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_TWS_1
        let logDataStatusLeft = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let logDataStatusRight = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let count = try reader.readUInt8()
        var data: [SafeListeningData1] = []
        data.reserveCapacity(Int(count))
        for _ in 0..<count {
            let entry = try SafeListeningData1.read(from: &reader)
            data.append(entry)
        }
        return Self(
            command: command,
            type: type,
            logDataStatusLeft: logDataStatusLeft,
            logDataStatusRight: logDataStatusRight,
            data: data
        )
    }
}

// MARK: SafeListeningNotifyStatusTws2 (EXTERN)

public struct SafeListeningNotifyStatusTws2: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_STATUS
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_2
    public var logDataStatusLeft: SafeListeningLogDataStatus
    public var logDataStatusRight: SafeListeningLogDataStatus
    public var data: [SafeListeningData2]

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_STATUS,
        type: SafeListeningInquiredType = .SAFE_LISTENING_TWS_2,
        logDataStatusLeft: SafeListeningLogDataStatus = .DISCONNECTED,
        logDataStatusRight: SafeListeningLogDataStatus = .DISCONNECTED,
        data: [SafeListeningData2] = []
    ) {
        self.command = command
        self.type = type
        self.logDataStatusLeft = logDataStatusLeft
        self.logDataStatusRight = logDataStatusRight
        self.data = data
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(logDataStatusLeft.rawValue)
        writer.writeUInt8(logDataStatusRight.rawValue)
        precondition(data.count <= 255, "SafeListeningData2 array too long")
        writer.writeUInt8(UInt8(data.count))
        for entry in data {
            entry.write(to: &writer)
        }
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_TWS_2
        let logDataStatusLeft = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let logDataStatusRight = SafeListeningLogDataStatus(rawValue: try reader.readUInt8()) ?? .DISCONNECTED
        let count = try reader.readUInt8()
        var data: [SafeListeningData2] = []
        data.reserveCapacity(Int(count))
        for _ in 0..<count {
            let entry = try SafeListeningData2.read(from: &reader)
            data.append(entry)
        }
        return Self(
            command: command,
            type: type,
            logDataStatusLeft: logDataStatusLeft,
            logDataStatusRight: logDataStatusRight,
            data: data
        )
    }
}

// MARK: SafeListeningNotifyStatusSVC

public struct SafeListeningNotifyStatusSVC: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_STATUS
    public var type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL
    public var whoStandardLevel: SafeListeningWHOStandardLevel

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_STATUS,
        type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL,
        whoStandardLevel: SafeListeningWHOStandardLevel = .NORMAL
    ) {
        self.command = command
        self.type = type
        self.whoStandardLevel = whoStandardLevel
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(whoStandardLevel.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_VOLUME_CONTROL
        let whoStandardLevel = SafeListeningWHOStandardLevel(rawValue: try reader.readUInt8()) ?? .NORMAL
        return Self(command: command, type: type, whoStandardLevel: whoStandardLevel)
    }
}

// MARK: SafeListeningGetParam

public struct SafeListeningGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_GET_PARAM
    public var inquiredType: SafeListeningInquiredType

    public init(
        command: T2Command = .SAFE_LISTENING_GET_PARAM,
        inquiredType: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    ) {
        self.command = command
        self.inquiredType = inquiredType
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        return Self(command: command, inquiredType: inquiredType)
    }
}

// MARK: SafeListeningRetParam

public struct SafeListeningRetParam: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_PARAM
    public var inquiredType: SafeListeningInquiredType
    public var availability: MessageMdrV2EnableDisable

    public init(
        command: T2Command = .SAFE_LISTENING_RET_PARAM,
        inquiredType: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        availability: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.availability = availability
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        writer.writeUInt8(availability.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let availability = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(command: command, inquiredType: inquiredType, availability: availability)
    }
}

// MARK: SafeListeningSetParamSL

public struct SafeListeningSetParamSL: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_SET_PARAM
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    public var safeListeningMode: MessageMdrV2EnableDisable
    public var previewMode: MessageMdrV2EnableDisable

    public init(
        command: T2Command = .SAFE_LISTENING_SET_PARAM,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        safeListeningMode: MessageMdrV2EnableDisable = .ENABLE,
        previewMode: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.safeListeningMode = safeListeningMode
        self.previewMode = previewMode
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(safeListeningMode.rawValue)
        writer.writeUInt8(previewMode.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let safeListeningMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let previewMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, safeListeningMode: safeListeningMode, previewMode: previewMode)
    }
}

// MARK: SafeListeningSetParamSVC

public struct SafeListeningSetParamSVC: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_SET_PARAM
    public var type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL
    public var volumeLimitationMode: MessageMdrV2EnableDisable
    public var safeVolumeControlMode: MessageMdrV2EnableDisable

    public init(
        command: T2Command = .SAFE_LISTENING_SET_PARAM,
        type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL,
        volumeLimitationMode: MessageMdrV2EnableDisable = .ENABLE,
        safeVolumeControlMode: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.command = command
        self.type = type
        self.volumeLimitationMode = volumeLimitationMode
        self.safeVolumeControlMode = safeVolumeControlMode
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(volumeLimitationMode.rawValue)
        writer.writeUInt8(safeVolumeControlMode.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_VOLUME_CONTROL
        let volumeLimitationMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let safeVolumeControlMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(
            command: command,
            type: type,
            volumeLimitationMode: volumeLimitationMode,
            safeVolumeControlMode: safeVolumeControlMode
        )
    }
}

// MARK: SafeListeningNotifyParamSL

public struct SafeListeningNotifyParamSL: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_PARAM
    public var type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
    public var safeListeningMode: MessageMdrV2EnableDisable
    public var previewMode: MessageMdrV2EnableDisable

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_PARAM,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        safeListeningMode: MessageMdrV2EnableDisable = .ENABLE,
        previewMode: MessageMdrV2EnableDisable = .DISABLE
    ) {
        self.command = command
        self.type = type
        self.safeListeningMode = safeListeningMode
        self.previewMode = previewMode
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(safeListeningMode.rawValue)
        writer.writeUInt8(previewMode.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let safeListeningMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let previewMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .DISABLE
        return Self(command: command, type: type, safeListeningMode: safeListeningMode, previewMode: previewMode)
    }
}

// MARK: SafeListeningNotifyParamSVC

public struct SafeListeningNotifyParamSVC: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_NTFY_PARAM
    public var type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL
    public var volumeLimitationMode: MessageMdrV2EnableDisable
    public var safeVolumeControlMode: MessageMdrV2EnableDisable

    public init(
        command: T2Command = .SAFE_LISTENING_NTFY_PARAM,
        type: SafeListeningInquiredType = .SAFE_VOLUME_CONTROL,
        volumeLimitationMode: MessageMdrV2EnableDisable = .ENABLE,
        safeVolumeControlMode: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.command = command
        self.type = type
        self.volumeLimitationMode = volumeLimitationMode
        self.safeVolumeControlMode = safeVolumeControlMode
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(volumeLimitationMode.rawValue)
        writer.writeUInt8(safeVolumeControlMode.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_VOLUME_CONTROL
        let volumeLimitationMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        let safeVolumeControlMode = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(
            command: command,
            type: type,
            volumeLimitationMode: volumeLimitationMode,
            safeVolumeControlMode: safeVolumeControlMode
        )
    }
}

// MARK: SafeListeningGetExtendedParam

public struct SafeListeningGetExtendedParam: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_GET_EXTENDED_PARAM
    public var type: SafeListeningInquiredType

    public init(
        command: T2Command = .SAFE_LISTENING_GET_EXTENDED_PARAM,
        type: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1
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
        let type = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        return Self(command: command, type: type)
    }
}

// MARK: SafeListeningRetExtendedParam

public struct SafeListeningRetExtendedParam: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .SAFE_LISTENING_RET_EXTENDED_PARAM
    public var inquiredType: SafeListeningInquiredType
    public var levelPerPeriod: UInt8
    public var errorCause: SafeListeningErrorCause

    public init(
        command: T2Command = .SAFE_LISTENING_RET_EXTENDED_PARAM,
        inquiredType: SafeListeningInquiredType = .SAFE_LISTENING_HBS_1,
        levelPerPeriod: UInt8 = 0,
        errorCause: SafeListeningErrorCause = .NOT_PLAYING
    ) {
        self.command = command
        self.inquiredType = inquiredType
        self.levelPerPeriod = levelPerPeriod
        self.errorCause = errorCause
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(inquiredType.rawValue)
        writer.writeUInt8(levelPerPeriod)
        writer.writeUInt8(errorCause.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let inquiredType = SafeListeningInquiredType(rawValue: try reader.readUInt8()) ?? .SAFE_LISTENING_HBS_1
        let levelPerPeriod = try reader.readUInt8()
        let errorCause = SafeListeningErrorCause(rawValue: try reader.readUInt8()) ?? .NOT_PLAYING
        return Self(
            command: command,
            inquiredType: inquiredType,
            levelPerPeriod: levelPerPeriod,
            errorCause: errorCause
        )
    }
}
