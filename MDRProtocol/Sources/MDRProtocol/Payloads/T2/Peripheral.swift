import Foundation

// MARK: - T2 Peripheral payloads from ProtocolV2T2.hpp

// MARK: PeripheralGetStatus

public struct PeripheralGetStatus: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_GET_STATUS
    public var type: PeripheralInquiredType

    public init(
        command: T2Command = .PERI_GET_STATUS,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
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
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        return Self(command: command, type: type)
    }
}

// MARK: PeripheralStatusPairingDeviceManagementCommon

public struct PeripheralStatusPairingDeviceManagementCommon: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_RET_STATUS
    public var type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
    public var btMode: PeripheralBluetoothMode
    public var enableDisableStatus: MessageMdrV2EnableDisable

    public init(
        command: T2Command = .PERI_RET_STATUS,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
        btMode: PeripheralBluetoothMode = .NORMAL_MODE,
        enableDisableStatus: MessageMdrV2EnableDisable = .ENABLE
    ) {
        self.command = command
        self.type = type
        self.btMode = btMode
        self.enableDisableStatus = enableDisableStatus
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(btMode.rawValue)
        writer.writeUInt8(enableDisableStatus.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        let btMode = PeripheralBluetoothMode(rawValue: try reader.readUInt8()) ?? .NORMAL_MODE
        let enableDisableStatus = MessageMdrV2EnableDisable(rawValue: try reader.readUInt8()) ?? .ENABLE
        return Self(command: command, type: type, btMode: btMode, enableDisableStatus: enableDisableStatus)
    }
}

// MARK: PeripheralDeviceInfo (MDRReadWritable sub-struct)

public struct PeripheralDeviceInfo: Equatable, Sendable, MDRReadWritable {
    public var btDeviceAddress: Data
    public var connectedStatus: UInt8
    public var btFriendlyName: PrefixedString

    public init(
        btDeviceAddress: Data = Data(count: 17),
        connectedStatus: UInt8 = 0,
        btFriendlyName: PrefixedString = PrefixedString()
    ) {
        self.btDeviceAddress = btDeviceAddress
        self.connectedStatus = connectedStatus
        self.btFriendlyName = btFriendlyName
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let btDeviceAddress = try reader.readBytes(count: 17)
        let connectedStatus = try reader.readUInt8()
        let btFriendlyName = try PrefixedString.read(from: &reader)
        return Self(
            btDeviceAddress: btDeviceAddress,
            connectedStatus: connectedStatus,
            btFriendlyName: btFriendlyName
        )
    }

    public func write(to writer: inout DataWriter) {
        writer.writeData(btDeviceAddress)
        writer.writeUInt8(connectedStatus)
        btFriendlyName.write(to: &writer)
    }
}

// MARK: PeripheralDeviceInfoWithBluetoothClassOfDevice (MDRReadWritable sub-struct)

public struct PeripheralDeviceInfoWithBluetoothClassOfDevice: Equatable, Sendable, MDRReadWritable {
    public var btDeviceAddress: Data
    public var connectedStatus: UInt8
    public var bluetoothClassOfDevice: Int24BE
    public var btFriendlyName: PrefixedString

    public init(
        btDeviceAddress: Data = Data(count: 17),
        connectedStatus: UInt8 = 0,
        bluetoothClassOfDevice: Int24BE = Int24BE(),
        btFriendlyName: PrefixedString = PrefixedString()
    ) {
        self.btDeviceAddress = btDeviceAddress
        self.connectedStatus = connectedStatus
        self.bluetoothClassOfDevice = bluetoothClassOfDevice
        self.btFriendlyName = btFriendlyName
    }

    public static func read(from reader: inout DataReader) throws -> Self {
        let btDeviceAddress = try reader.readBytes(count: 17)
        let connectedStatus = try reader.readUInt8()
        let bluetoothClassOfDevice = try reader.readInt24BE()
        let btFriendlyName = try PrefixedString.read(from: &reader)
        return Self(
            btDeviceAddress: btDeviceAddress,
            connectedStatus: connectedStatus,
            bluetoothClassOfDevice: bluetoothClassOfDevice,
            btFriendlyName: btFriendlyName
        )
    }

    public func write(to writer: inout DataWriter) {
        writer.writeData(btDeviceAddress)
        writer.writeUInt8(connectedStatus)
        writer.writeInt24BE(bluetoothClassOfDevice)
        btFriendlyName.write(to: &writer)
    }
}

// MARK: PeripheralGetParam

public struct PeripheralGetParam: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_GET_PARAM
    public var type: PeripheralInquiredType

    public init(
        command: T2Command = .PERI_GET_PARAM,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
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
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        return Self(command: command, type: type)
    }
}

// MARK: PeripheralParamPairingDeviceManagementClassicBt (EXTERN)

public struct PeripheralParamPairingDeviceManagementClassicBt: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_RET_PARAM
    public var type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
    public var deviceList: MDRArray<PeripheralDeviceInfo> = MDRArray()
    public var playbackDevice: UInt8 = 0

    public init(
        command: T2Command = .PERI_RET_PARAM,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
        deviceList: MDRArray<PeripheralDeviceInfo> = MDRArray(),
        playbackDevice: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.deviceList = deviceList
        self.playbackDevice = playbackDevice
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        deviceList.write(to: &writer)
        writer.writeUInt8(playbackDevice)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        let deviceList = try MDRArray<PeripheralDeviceInfo>.read(from: &reader)
        let playbackDevice = try reader.readUInt8()
        return Self(
            command: command,
            type: type,
            deviceList: deviceList,
            playbackDevice: playbackDevice
        )
    }
}

// MARK: PeripheralParamSourceSwitchControl

public struct PeripheralParamSourceSwitchControl: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_RET_PARAM
    public var type: PeripheralInquiredType = .SOURCE_SWITCH_CONTROL
    public var sourceKeeping: MessageMdrV2OnOffSettingValue

    public init(
        command: T2Command = .PERI_RET_PARAM,
        type: PeripheralInquiredType = .SOURCE_SWITCH_CONTROL,
        sourceKeeping: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.sourceKeeping = sourceKeeping
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(sourceKeeping.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .SOURCE_SWITCH_CONTROL
        let sourceKeeping = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, sourceKeeping: sourceKeeping)
    }
}

// MARK: PeripheralParamPairingDeviceManagementWithBluetoothClassOfDevice (EXTERN)

public struct PeripheralParamPairingDeviceManagementWithBluetoothClassOfDevice: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_RET_PARAM
    public var type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE
    public var deviceList: MDRArray<PeripheralDeviceInfoWithBluetoothClassOfDevice> = MDRArray()
    public var playbackDevice: UInt8 = 0

    public init(
        command: T2Command = .PERI_RET_PARAM,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE,
        deviceList: MDRArray<PeripheralDeviceInfoWithBluetoothClassOfDevice> = MDRArray(),
        playbackDevice: UInt8 = 0
    ) {
        self.command = command
        self.type = type
        self.deviceList = deviceList
        self.playbackDevice = playbackDevice
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        deviceList.write(to: &writer)
        writer.writeUInt8(playbackDevice)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE
        let deviceList = try MDRArray<PeripheralDeviceInfoWithBluetoothClassOfDevice>.read(from: &reader)
        let playbackDevice = try reader.readUInt8()
        return Self(
            command: command,
            type: type,
            deviceList: deviceList,
            playbackDevice: playbackDevice
        )
    }
}

// MARK: PeripheralParamMusicHandOverSetting

public struct PeripheralParamMusicHandOverSetting: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_RET_PARAM
    public var type: PeripheralInquiredType = .MUSIC_HAND_OVER_SETTING
    public var isOn: MessageMdrV2OnOffSettingValue

    public init(
        command: T2Command = .PERI_RET_PARAM,
        type: PeripheralInquiredType = .MUSIC_HAND_OVER_SETTING,
        isOn: MessageMdrV2OnOffSettingValue = .OFF
    ) {
        self.command = command
        self.type = type
        self.isOn = isOn
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(isOn.rawValue)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .MUSIC_HAND_OVER_SETTING
        let isOn = MessageMdrV2OnOffSettingValue(rawValue: try reader.readUInt8()) ?? .OFF
        return Self(command: command, type: type, isOn: isOn)
    }
}

// MARK: PeripheralSetExtendedParamParingDeviceManagementCommon

public struct PeripheralSetExtendedParamParingDeviceManagementCommon: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_SET_EXTENDED_PARAM
    public var type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
    public var connectivityActionType: ConnectivityActionType
    public var targetBdAddress: Data

    public init(
        command: T2Command = .PERI_SET_EXTENDED_PARAM,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
        connectivityActionType: ConnectivityActionType = .DISCONNECT,
        targetBdAddress: Data = Data(count: 17)
    ) {
        self.command = command
        self.type = type
        self.connectivityActionType = connectivityActionType
        self.targetBdAddress = targetBdAddress
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(connectivityActionType.rawValue)
        writer.writeData(targetBdAddress)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        let connectivityActionType = ConnectivityActionType(rawValue: try reader.readUInt8()) ?? .DISCONNECT
        let targetBdAddress = try reader.readBytes(count: 17)
        return Self(
            command: command,
            type: type,
            connectivityActionType: connectivityActionType,
            targetBdAddress: targetBdAddress
        )
    }
}

// MARK: PeripheralSetExtendedParamSourceSwitchControl

public struct PeripheralSetExtendedParamSourceSwitchControl: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_SET_EXTENDED_PARAM
    public var type: PeripheralInquiredType = .SOURCE_SWITCH_CONTROL
    public var targetBdAddress: Data

    public init(
        command: T2Command = .PERI_SET_EXTENDED_PARAM,
        type: PeripheralInquiredType = .SOURCE_SWITCH_CONTROL,
        targetBdAddress: Data = Data(count: 17)
    ) {
        self.command = command
        self.type = type
        self.targetBdAddress = targetBdAddress
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeData(targetBdAddress)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .SOURCE_SWITCH_CONTROL
        let targetBdAddress = try reader.readBytes(count: 17)
        return Self(command: command, type: type, targetBdAddress: targetBdAddress)
    }
}

// MARK: PeripheralNotifyExtendedParamParingDeviceManagementCommon

public struct PeripheralNotifyExtendedParamParingDeviceManagementCommon: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_NTFY_EXTENDED_PARAM
    public var type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
    public var connectivityActionType: ConnectivityActionType
    public var peripheralResult: PeripheralResult
    public var btDeviceAddress: Data

    public init(
        command: T2Command = .PERI_NTFY_EXTENDED_PARAM,
        type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
        connectivityActionType: ConnectivityActionType = .DISCONNECT,
        peripheralResult: PeripheralResult = .DISCONNECTION_SUCCESS,
        btDeviceAddress: Data = Data(count: 17)
    ) {
        self.command = command
        self.type = type
        self.connectivityActionType = connectivityActionType
        self.peripheralResult = peripheralResult
        self.btDeviceAddress = btDeviceAddress
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(connectivityActionType.rawValue)
        writer.writeUInt8(peripheralResult.rawValue)
        writer.writeData(btDeviceAddress)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        let connectivityActionType = ConnectivityActionType(rawValue: try reader.readUInt8()) ?? .DISCONNECT
        let peripheralResult = PeripheralResult(rawValue: try reader.readUInt8()) ?? .DISCONNECTION_SUCCESS
        let btDeviceAddress = try reader.readBytes(count: 17)
        return Self(
            command: command,
            type: type,
            connectivityActionType: connectivityActionType,
            peripheralResult: peripheralResult,
            btDeviceAddress: btDeviceAddress
        )
    }
}

// MARK: PeripheralNotifyExtendedParamSourceSwitchControl

public struct PeripheralNotifyExtendedParamSourceSwitchControl: Equatable, Sendable, MDRSerializable {
    public var command: T2Command = .PERI_NTFY_EXTENDED_PARAM
    public var type: PeripheralInquiredType = .SOURCE_SWITCH_CONTROL
    public var result: SourceSwitchControlResult
    public var targetBdAddress: Data

    public init(
        command: T2Command = .PERI_NTFY_EXTENDED_PARAM,
        type: PeripheralInquiredType = .SOURCE_SWITCH_CONTROL,
        result: SourceSwitchControlResult = .SUCCESS,
        targetBdAddress: Data = Data(count: 17)
    ) {
        self.command = command
        self.type = type
        self.result = result
        self.targetBdAddress = targetBdAddress
    }

    public func serialize(to writer: inout DataWriter) {
        writer.writeUInt8(command.rawValue)
        writer.writeUInt8(type.rawValue)
        writer.writeUInt8(result.rawValue)
        writer.writeData(targetBdAddress)
    }

    public static func deserialize(from reader: inout DataReader) throws -> Self {
        let command = T2Command(rawValue: try reader.readUInt8()) ?? .UNKNOWN
        let type = PeripheralInquiredType(rawValue: try reader.readUInt8()) ?? .SOURCE_SWITCH_CONTROL
        let result = SourceSwitchControlResult(rawValue: try reader.readUInt8()) ?? .SUCCESS
        let targetBdAddress = try reader.readBytes(count: 17)
        return Self(command: command, type: type, result: result, targetBdAddress: targetBdAddress)
    }
}
