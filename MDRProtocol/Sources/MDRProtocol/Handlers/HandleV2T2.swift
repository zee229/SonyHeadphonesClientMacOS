import Foundation

// MARK: - T2 Command Handlers

extension MDRHeadphones {

    // MARK: Voice Guidance Param

    func handleVoiceGuidanceParamT2(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let vgType = VoiceGuidanceInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch vgType {
        case .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH:
            guard let res = try? VoiceGuidanceParamSettingMtk.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            voiceGuidanceEnabled.overwrite(res.settingValue == .ON)
            return MDREvent.voiceGuidanceEnable.rawValue
        case .VOLUME:
            guard let res = try? VoiceGuidanceParamVolume.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            voiceGuidanceVolume.overwrite(Int(res.volumeValue))
            return MDREvent.voiceGuidanceVolume.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Peripheral Status (Pairing Mode)

    func handlePeripheralStatusT2(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let periType = PeripheralInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch periType {
        case .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE,
             .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT:
            guard let res = try? PeripheralStatusPairingDeviceManagementCommon.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            pairingMode.overwrite(
                res.enableDisableStatus == .ENABLE &&
                res.btMode == .INQUIRY_SCAN_MODE
            )
            return MDREvent.bluetoothMode.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Peripheral Notify Extended Param (Multipoint Switch)

    func handlePeripheralNotifyExtendedParamT2(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let periType = PeripheralInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch periType {
        case .SOURCE_SWITCH_CONTROL:
            guard let res = try? PeripheralNotifyExtendedParamSourceSwitchControl.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            let mac = String(data: res.targetBdAddress, encoding: .utf8) ?? ""
            multipointDeviceMac.overwrite(mac)
            return MDREvent.multipointSwitch.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Peripheral Param (Paired Devices)

    func handlePeripheralParamT2(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let periType = PeripheralInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch periType {
        case .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT:
            guard let res = try? PeripheralParamPairingDeviceManagementClassicBt.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            pairedDevicesPlaybackDeviceID = res.playbackDevice
            pairedDevices = res.deviceList.value.enumerated().map { (i, dev) in
                let mac = String(data: dev.btDeviceAddress, encoding: .utf8) ?? ""
                if dev.connectedStatus == res.playbackDevice {
                    multipointDeviceMac.overwrite(mac)
                }
                return PeripheralDevice(
                    macAddress: mac,
                    name: dev.btFriendlyName.value,
                    connected: dev.connectedStatus != 0
                )
            }
            return MDREvent.connectedDevices.rawValue
        case .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE:
            guard let res = try? PeripheralParamPairingDeviceManagementWithBluetoothClassOfDevice.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            pairedDevicesPlaybackDeviceID = res.playbackDevice
            pairedDevices = res.deviceList.value.enumerated().map { (i, dev) in
                let mac = String(data: dev.btDeviceAddress, encoding: .utf8) ?? ""
                if dev.connectedStatus == res.playbackDevice {
                    multipointDeviceMac.overwrite(mac)
                }
                return PeripheralDevice(
                    macAddress: mac,
                    name: dev.btFriendlyName.value,
                    connected: dev.connectedStatus != 0
                )
            }
            return MDREvent.connectedDevices.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Safe Listening Params

    func handleSafeListeningParamsT2(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let slType = SafeListeningInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch slType {
        case .SAFE_LISTENING_HBS_1, .SAFE_LISTENING_HBS_2,
             .SAFE_LISTENING_TWS_1, .SAFE_LISTENING_TWS_2:
            guard let res = try? SafeListeningNotifyParamSL.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            safeListeningPreviewMode.overwrite(res.previewMode == .ENABLE)
            return MDREvent.safeListeningParam.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Safe Listening Extended Param (Sound Pressure)

    func handleSafeListeningExtendedParamT2(_ data: Data) -> Int {
        var reader = DataReader(Data(data))
        guard let res = try? SafeListeningRetExtendedParam.deserialize(from: &reader) else {
            return MDREvent.unhandled.rawValue
        }
        safeListeningSoundPressure = Int(res.levelPerPeriod)
        return MDREvent.soundPressure.rawValue
    }
}
