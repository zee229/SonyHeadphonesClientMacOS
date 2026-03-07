import Foundation

extension MDRHeadphones {

    /// Port of RequestInitV2 from HeadphonesV2.cpp.
    /// Performs the full initialization handshake with the headphones.
    /// Commands are sent sequentially via the command queue (one at a time, ACK-gated).
    public func requestInitV2() {
        setTaskRunning(true)

        // Phase 1: Protocol Info
        queueCommand(ConnectGetProtocolInfo())
        setQueueDrainCallback { [self] in
            // ACK received. Now wait for protocol info DATA response.
            setAwaiter(.protocolInfo) { [self] _ in
                guard protocolInfo.hasTable1 else {
                    setTaskError(MDRError.protocolError("Device doesn't support MDR V2 Table 1"))
                    return
                }

                // Phase 2: Device info + Support functions (sequential)
                queueCommand(ConnectGetCapabilityInfo())
                queueCommand(ConnectGetDeviceInfo(deviceInfoType: .FW_VERSION))
                queueCommand(ConnectGetDeviceInfo(deviceInfoType: .MODEL_NAME))
                queueCommand(ConnectGetDeviceInfo(deviceInfoType: .SERIES_AND_COLOR_INFO))
                queueCommand(ConnectGetSupportFunction())
                setQueueDrainCallback { [self] in
                    // All ACK'd. Wait for support function DATA response.
                    setAwaiter(.supportFunction) { [self] _ in
                        if protocolInfo.hasTable2 {
                            queueCommand(T2ConnectGetSupportFunction(), type: .dataMdrNo2)
                            setQueueDrainCallback { [self] in
                                setAwaiter(.supportFunction) { [self] _ in
                                    requestInitV2Phase2()
                                }
                            }
                        } else {
                            requestInitV2Phase2()
                        }
                    }
                }
            }
        }
    }

    /// Phase 2: After support functions are loaded, query all supported features.
    func requestInitV2Phase2() {
        let lang = DisplayLanguage.ENGLISH

        // General Settings
        if support.contains(.GENERAL_SETTING_1) {
            queueCommand(GsGetCapability(type: .GENERAL_SETTING1, displayLanguage: lang))
            queueCommand(GsGetParam(type: .GENERAL_SETTING1))
        }
        if support.contains(.GENERAL_SETTING_2) {
            queueCommand(GsGetCapability(type: .GENERAL_SETTING2, displayLanguage: lang))
            queueCommand(GsGetParam(type: .GENERAL_SETTING2))
        }
        if support.contains(.GENERAL_SETTING_3) {
            queueCommand(GsGetCapability(type: .GENERAL_SETTING3, displayLanguage: lang))
            queueCommand(GsGetParam(type: .GENERAL_SETTING3))
        }
        if support.contains(.GENERAL_SETTING_4) {
            queueCommand(GsGetCapability(type: .GENERAL_SETTING4, displayLanguage: lang))
            queueCommand(GsGetParam(type: .GENERAL_SETTING4))
        }

        // DSEE Capability
        if support.contains(.UPSCALING_AUTO_OFF) {
            queueCommand(AudioGetCapability(type: .UPSCALING))
        }

        // Alert subscription
        if support.contains(.FIXED_MESSAGE) {
            queueCommand(AlertSetStatusFixedMessage(status: .ENABLE))
        }

        // Codec
        if support.contains(.CODEC_INDICATOR) {
            queueCommand(CommonGetStatus(type: .AUDIO_CODEC))
        }

        // Playback
        queueCommand(GetPlayParam(type: .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT))
        queueCommand(GetPlayParam(type: .MUSIC_VOLUME))
        queueCommand(GetPlayStatus(type: .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT))

        // NC/ASM
        if support.contains(.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT) {
            queueCommand(NcAsmGetParam(type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS))
        } else if support.contains(.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT_NOISE_ADAPTATION) {
            queueCommand(NcAsmGetParam(type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA))
        } else if support.contains(.AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT) {
            queueCommand(NcAsmGetParam(type: .ASM_SEAMLESS))
        }

        // Pairing Management
        let hasPairingWithClass = support.contains(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE_CLASSIC_BT)
            || support.contains(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE_CLASSIC_LE)
        if hasPairingWithClass {
            queueCommand(PeripheralGetStatus(type: .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE), type: .dataMdrNo2)
            queueCommand(PeripheralGetParam(type: .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE), type: .dataMdrNo2)
        }
        if support.contains(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT) {
            queueCommand(PeripheralGetStatus(type: .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT), type: .dataMdrNo2)
            queueCommand(PeripheralGetParam(type: .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT), type: .dataMdrNo2)
        }

        // Speak To Chat
        if support.contains(.SMART_TALKING_MODE_TYPE2) {
            queueCommand(SystemGetParam(type: .SMART_TALKING_MODE_TYPE2))
            queueCommand(SystemGetExtParam(type: .SMART_TALKING_MODE_TYPE2))
        }

        // Listening Mode
        if support.contains(.LISTENING_OPTION) {
            queueCommand(AudioGetParam(type: .BGM_MODE))
            queueCommand(AudioGetParam(type: .UPMIX_CINEMA))
        }

        // EQ
        queueCommand(EqEbbGetStatus(type: .PRESET_EQ))
        queueCommand(EqEbbGetParam())

        // Connection Quality
        if support.contains(.CONNECTION_MODE_SOUND_QUALITY_CONNECTION_QUALITY) {
            queueCommand(AudioGetParam(type: .CONNECTION_MODE))
        }

        // DSEE Status/Param
        if support.contains(.UPSCALING_AUTO_OFF) {
            queueCommand(AudioGetStatus(type: .UPSCALING))
            queueCommand(AudioGetParam(type: .UPSCALING))
        }

        // Touch Sensor
        if support.contains(.ASSIGNABLE_SETTING) {
            queueCommand(SystemGetParam(type: .ASSIGNABLE_SETTINGS))
        }

        // NC/AMB Toggle
        if support.contains(.AMBIENT_SOUND_CONTROL_MODE_SELECT) {
            queueCommand(NcAsmGetParam(type: .NC_AMB_TOGGLE))
        }

        // Head Gesture
        if support.contains(.HEAD_GESTURE_ON_OFF_TRAINING) {
            queueCommand(SystemGetParam(type: .HEAD_GESTURE_ON_OFF))
        }

        // Auto Power Off
        if support.contains(.AUTO_POWER_OFF) {
            queueCommand(PowerGetParam(type: .AUTO_POWER_OFF))
        } else if support.contains(.AUTO_POWER_OFF_WITH_WEARING_DETECTION) {
            queueCommand(PowerGetParam(type: .AUTO_POWER_OFF_WEARING_DETECTION))
        }

        // Auto Pause
        queueCommand(SystemGetParam(type: .PLAYBACK_CONTROL_BY_WEARING))

        // Voice Guidance
        if protocolInfo.hasTable2 {
            queueCommand(VoiceGuidanceGetParam(type: .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH), type: .dataMdrNo2)
            queueCommand(VoiceGuidanceGetParam(type: .VOLUME), type: .dataMdrNo2)
        }

        // Log Set Status (raw bytes, no formal struct)
        let logSetStatusPayload = Data([T1Command.LOG_SET_STATUS.rawValue, 0x01, 0x00])
        queueCommandRaw(logSetStatusPayload, type: .dataMdr)

        setQueueDrainCallback { [self] in
            setTaskResult(MDREvent.taskInitOK.rawValue)
        }
    }
}
