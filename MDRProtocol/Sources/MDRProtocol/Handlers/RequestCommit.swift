import Foundation

extension MDRHeadphones {

    /// Port of RequestCommitV2 from HeadphonesV2.cpp.
    /// Sends all dirty property changes to the headphones.
    public func requestCommitV2() {
        setTaskRunning(true)

        // Shutdown
        if shutdown.isDirty {
            if support.contains(.POWER_OFF) && shutdown.desired {
                queueCommand(PowerSetStatusPowerOff())
            } else {
                shutdown.overwrite(false)
            }
        }

        // NC/ASM
        if ncAsmAmbientLevel.isDirty || ncAsmEnabled.isDirty || ncAsmMode.isDirty ||
           ncAsmFocusOnVoice.isDirty || ncAsmAutoAsmEnabled.isDirty || ncAsmNoiseAdaptiveSensitivity.isDirty {
            if support.contains(.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT_NOISE_ADAPTATION) {
                queueCommand(NcAsmParamModeNcDualModeSwitchAsmSeamlessNa(
                    command: .NCASM_SET_PARAM,
                    type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA,
                    valueChangeStatus: .CHANGED,
                    ncAsmTotalEffect: ncAsmEnabled.desired ? .ON : .OFF,
                    ncAsmMode: ncAsmMode.desired,
                    ambientSoundMode: ncAsmFocusOnVoice.desired ? .VOICE : .NORMAL,
                    ambientSoundLevelValue: UInt8(ncAsmAmbientLevel.desired),
                    noiseAdaptiveOnOffValue: ncAsmAutoAsmEnabled.desired ? .ON : .OFF,
                    noiseAdaptiveSensitivitySettings: ncAsmNoiseAdaptiveSensitivity.desired
                ))
            } else if support.contains(.AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT) {
                queueCommand(NcAsmParamAsmSeamless(
                    command: .NCASM_SET_PARAM,
                    type: .ASM_SEAMLESS,
                    valueChangeStatus: .CHANGED,
                    ncAsmTotalEffect: ncAsmEnabled.desired ? .ON : .OFF,
                    ambientSoundMode: ncAsmFocusOnVoice.desired ? .VOICE : .NORMAL,
                    ambientSoundLevelValue: UInt8(ncAsmAmbientLevel.desired)
                ))
            } else {
                queueCommand(NcAsmParamModeNcDualModeSwitchAsmSeamless(
                    command: .NCASM_SET_PARAM,
                    type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS,
                    valueChangeStatus: .CHANGED,
                    ncAsmTotalEffect: ncAsmEnabled.desired ? .ON : .OFF,
                    ncAsmMode: ncAsmMode.desired,
                    ambientSoundMode: ncAsmFocusOnVoice.desired ? .VOICE : .NORMAL,
                    ambientSoundLevelValue: UInt8(ncAsmAmbientLevel.desired)
                ))
            }
            ncAsmAmbientLevel.commit()
            ncAsmEnabled.commit()
            ncAsmMode.commit()
            ncAsmFocusOnVoice.commit()
            ncAsmAutoAsmEnabled.commit()
            ncAsmNoiseAdaptiveSensitivity.commit()
        }

        // NC/AMB Mode Toggle
        if support.contains(.AMBIENT_SOUND_CONTROL_MODE_SELECT) {
            if ncAsmButtonFunction.isDirty {
                queueCommand(NcAsmParamNcAmbToggle(
                    command: .NCASM_SET_PARAM,
                    type: .NC_AMB_TOGGLE,
                    function: ncAsmButtonFunction.desired
                ))
                ncAsmButtonFunction.commit()
            }
        }

        // Volume
        if playVolume.isDirty {
            queueCommand(PlayParamPlaybackControllerVolume(
                command: .PLAY_SET_PARAM,
                type: .MUSIC_VOLUME,
                volumeValue: UInt8(playVolume.desired)
            ))
            playVolume.commit()
        }

        // Play Control
        if playControl.isDirty {
            queueCommand(PlayStatusSetPlaybackController(
                command: .PLAY_SET_STATUS,
                type: .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
                status: .ENABLE,
                control: playControl.desired
            ))
            playControl.overwrite(.KEY_OFF)
        }

        // Multipoint Switch
        if multipointDeviceMac.isDirty {
            if multipointDeviceMac.desired.count != 17 {
                multipointDeviceMac.overwrite("")
            } else {
                queueCommand(PeripheralSetExtendedParamSourceSwitchControl(
                    targetBdAddress: Data(multipointDeviceMac.desired.utf8)
                ), type: .dataMdrNo2)
                multipointDeviceMac.commit()
            }
        }

        // Connection Ops (connect/disconnect/unpair)
        commitConnectionOps()

        // Speak To Chat
        if support.contains(.SMART_TALKING_MODE_TYPE2) {
            if speakToChatEnabled.isDirty {
                queueCommand(SystemParamSmartTalking(
                    base: SystemBase(command: .SYSTEM_SET_PARAM, type: .SMART_TALKING_MODE_TYPE2),
                    onOffValue: speakToChatEnabled.desired ? .ENABLE : .DISABLE,
                    previewModeOnOffValue: .DISABLE
                ))
                speakToChatEnabled.commit()
            }
            if speakToChatDetectSensitivity.isDirty || speakToModeOutTime.isDirty {
                queueCommand(SystemExtParamSmartTalkingMode2(
                    base: SystemExtBase(command: .SYSTEM_SET_EXT_PARAM, type: .SMART_TALKING_MODE_TYPE2),
                    detectSensitivity: speakToChatDetectSensitivity.desired,
                    modeOffTime: speakToModeOutTime.desired
                ))
                speakToChatDetectSensitivity.commit()
                speakToModeOutTime.commit()
            }
        }

        // Listening Mode
        if support.contains(.LISTENING_OPTION) {
            if bgmModeEnabled.isDirty || bgmModeRoomSize.isDirty {
                queueCommand(AudioParamBGMMode(
                    command: .AUDIO_SET_PARAM,
                    type: .BGM_MODE,
                    onOffSettingValue: bgmModeEnabled.desired ? .ENABLE : .DISABLE,
                    targetRoomSize: bgmModeRoomSize.desired
                ))
                bgmModeEnabled.commit()
                bgmModeRoomSize.commit()
            }
            if upmixCinemaEnabled.isDirty {
                queueCommand(AudioParamUpmixCinema(
                    command: .AUDIO_SET_PARAM,
                    type: .UPMIX_CINEMA,
                    onOffSettingValue: upmixCinemaEnabled.desired ? .ENABLE : .DISABLE
                ))
                upmixCinemaEnabled.commit()
            }
        }

        // EQ Preset
        if eqPresetId.isDirty {
            queueCommand(EqEbbParamEq(
                command: .EQEBB_SET_PARAM,
                type: .PRESET_EQ,
                presetId: eqPresetId.desired,
                bands: PodArray<UInt8>([])
            ))
            eqPresetId.commit()
            queueCommand(EqEbbGetParam())
        }

        // EQ Bands
        if eqConfig.isDirty || eqClearBass.isDirty {
            let bands = eqConfig.desired
            if bands.count == 0 {
                eqConfig.commit()
                eqClearBass.commit()
            } else {
                var rawBands: [UInt8] = []
                if bands.count == 5 {
                    rawBands = [UInt8(eqClearBass.desired + 10)]
                    rawBands += bands.map { UInt8($0 + 10) }
                } else if bands.count == 10 {
                    rawBands = bands.map { UInt8($0 + 6) }
                }
                queueCommand(EqEbbParamEq(
                    command: .EQEBB_SET_PARAM,
                    type: .PRESET_EQ,
                    presetId: eqPresetId.current,
                    bands: PodArray<UInt8>(rawBands)
                ))
                eqConfig.commit()
                eqClearBass.commit()
                queueCommand(EqEbbGetParam())
            }
        }

        // Connection Quality
        if support.contains(.CONNECTION_MODE_SOUND_QUALITY_CONNECTION_QUALITY) {
            if audioPriorityMode.isDirty {
                queueCommand(AudioParamConnection(
                    command: .AUDIO_SET_PARAM,
                    type: .CONNECTION_MODE,
                    settingValue: audioPriorityMode.desired
                ))
                audioPriorityMode.commit()
            }
        }

        // DSEE
        if support.contains(.UPSCALING_AUTO_OFF) {
            if upscalingEnabled.isDirty {
                queueCommand(AudioParamUpscaling(
                    command: .AUDIO_SET_PARAM,
                    type: .UPSCALING,
                    settingValue: upscalingEnabled.desired ? .AUTO : .OFF
                ))
                upscalingEnabled.commit()
            }
        }

        // Touch Functions
        if support.contains(.ASSIGNABLE_SETTING) {
            if touchFunctionLeft.isDirty || touchFunctionRight.isDirty {
                queueCommand(SystemParamAssignableSettings(
                    base: SystemBase(command: .SYSTEM_SET_PARAM, type: .ASSIGNABLE_SETTINGS),
                    presets: PodArray<UInt8>([touchFunctionLeft.desired.rawValue, touchFunctionRight.desired.rawValue])
                ))
                touchFunctionLeft.commit()
                touchFunctionRight.commit()
            }
        }

        // Head Gesture
        if support.contains(.HEAD_GESTURE_ON_OFF_TRAINING) {
            if headGestureEnabled.isDirty {
                queueCommand(SystemParamCommon(
                    base: SystemBase(command: .SYSTEM_SET_PARAM, type: .HEAD_GESTURE_ON_OFF),
                    settingValue: headGestureEnabled.desired ? .ENABLE : .DISABLE
                ))
                headGestureEnabled.commit()
            }
        }

        // Auto Power Off
        if support.contains(.AUTO_POWER_OFF) {
            if powerAutoOff.isDirty {
                queueCommand(PowerParamAutoPowerOff(
                    command: .POWER_SET_PARAM,
                    type: .AUTO_POWER_OFF,
                    currentPowerOffElements: powerAutoOff.desired,
                    lastSelectPowerOffElements: .POWER_OFF_IN_5_MIN
                ))
                powerAutoOff.commit()
            }
        } else if support.contains(.AUTO_POWER_OFF_WITH_WEARING_DETECTION) {
            if powerAutoOffWearingDetection.isDirty {
                queueCommand(PowerParamAutoPowerOffWithWearingDetection(
                    command: .POWER_SET_PARAM,
                    type: .AUTO_POWER_OFF_WEARING_DETECTION,
                    currentPowerOffElements: powerAutoOffWearingDetection.desired,
                    lastSelectPowerOffElements: .POWER_OFF_IN_5_MIN
                ))
                powerAutoOffWearingDetection.commit()
            }
        }

        // Auto Pause
        if support.contains(.PLAYBACK_CONTROL_BY_WEARING_REMOVING_HEADPHONE_ON_OFF) {
            if autoPauseEnabled.isDirty {
                queueCommand(SystemParamCommon(
                    base: SystemBase(command: .SYSTEM_SET_PARAM, type: .PLAYBACK_CONTROL_BY_WEARING),
                    settingValue: autoPauseEnabled.desired ? .ENABLE : .DISABLE
                ))
                autoPauseEnabled.commit()
            }
        }

        // Voice Guidance Enabled
        if voiceGuidanceEnabled.isDirty {
            queueCommand(VoiceGuidanceParamSettingMtk(
                command: .VOICE_GUIDANCE_SET_PARAM,
                type: .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH,
                settingValue: voiceGuidanceEnabled.desired ? .ON : .OFF
            ), type: .dataMdrNo2)
            voiceGuidanceEnabled.commit()
        }

        // Voice Guidance Volume
        if support.contains(MessageMdrV2FunctionType_Table2.VOICE_GUIDANCE_SETTING_MTK_TRANSFER_WITHOUT_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH_AND_VOLUME_ADJUSTMENT) {
            if voiceGuidanceVolume.isDirty {
                queueCommand(VoiceGuidanceSetParamVolume(
                    volumeValue: Int8(voiceGuidanceVolume.desired),
                    feedbackSound: .ON
                ), type: .dataMdrNo2)
                voiceGuidanceVolume.commit()
            }
        }

        // General Settings
        commitGeneralSettings()

        // Safe Listening
        if safeListeningPreviewMode.isDirty {
            commitSafeListening()
        }

        setQueueDrainCallback { [self] in
            setTaskResult(MDREvent.taskCommitOK.rawValue)
        }
    }

    // MARK: - Connection Ops

    private func commitConnectionOps() {
        var type: PeripheralInquiredType = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT

        let hasClassBT = support.contains(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE_CLASSIC_BT)
            || support.contains(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE_CLASSIC_LE)
        if hasClassBT {
            type = .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE
        } else if support.contains(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT) {
            type = .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT
        } else {
            pairedDeviceConnectMac.overwrite("")
            pairedDeviceDisconnectMac.overwrite("")
            pairedDeviceUnpairMac.overwrite("")
        }

        if pairedDeviceConnectMac.isDirty {
            queueCommand(PeripheralSetExtendedParamParingDeviceManagementCommon(
                type: type,
                connectivityActionType: .CONNECT,
                targetBdAddress: Data(pairedDeviceConnectMac.desired.utf8)
            ), type: .dataMdrNo2)
            pairedDeviceConnectMac.overwrite("")
        }

        if pairedDeviceDisconnectMac.isDirty {
            queueCommand(PeripheralSetExtendedParamParingDeviceManagementCommon(
                type: type,
                connectivityActionType: .DISCONNECT,
                targetBdAddress: Data(pairedDeviceDisconnectMac.desired.utf8)
            ), type: .dataMdrNo2)
            pairedDeviceDisconnectMac.overwrite("")
        }

        if pairedDeviceUnpairMac.isDirty {
            queueCommand(PeripheralSetExtendedParamParingDeviceManagementCommon(
                type: type,
                connectivityActionType: .UNPAIR,
                targetBdAddress: Data(pairedDeviceUnpairMac.desired.utf8)
            ), type: .dataMdrNo2)
            pairedDeviceUnpairMac.overwrite("")
        }

        // Pairing Mode
        if pairingMode.isDirty {
            queueCommand(PeripheralStatusPairingDeviceManagementCommon(
                command: .PERI_SET_STATUS,
                type: type,
                btMode: pairingMode.desired ? .INQUIRY_SCAN_MODE : .NORMAL_MODE,
                enableDisableStatus: .ENABLE
            ), type: .dataMdrNo2)
            pairingMode.commit()
        }
    }

    // MARK: - General Settings

    private func commitGeneralSettings() {
        if support.contains(.GENERAL_SETTING_1) && gsParamBool1.isDirty {
            queueCommand(GsParamBoolean(
                base: GsParamBase(command: .GENERAL_SETTING_SET_PARAM, type: .GENERAL_SETTING1, settingType: .BOOLEAN_TYPE),
                settingValue: gsParamBool1.desired ? .ON : .OFF
            ))
            gsParamBool1.commit()
        }
        if support.contains(.GENERAL_SETTING_2) && gsParamBool2.isDirty {
            queueCommand(GsParamBoolean(
                base: GsParamBase(command: .GENERAL_SETTING_SET_PARAM, type: .GENERAL_SETTING2, settingType: .BOOLEAN_TYPE),
                settingValue: gsParamBool2.desired ? .ON : .OFF
            ))
            gsParamBool2.commit()
        }
        if support.contains(.GENERAL_SETTING_3) && gsParamBool3.isDirty {
            queueCommand(GsParamBoolean(
                base: GsParamBase(command: .GENERAL_SETTING_SET_PARAM, type: .GENERAL_SETTING3, settingType: .BOOLEAN_TYPE),
                settingValue: gsParamBool3.desired ? .ON : .OFF
            ))
            gsParamBool3.commit()
        }
        if support.contains(.GENERAL_SETTING_4) && gsParamBool4.isDirty {
            queueCommand(GsParamBoolean(
                base: GsParamBase(command: .GENERAL_SETTING_SET_PARAM, type: .GENERAL_SETTING4, settingType: .BOOLEAN_TYPE),
                settingValue: gsParamBool4.desired ? .ON : .OFF
            ))
            gsParamBool4.commit()
        }
    }

    // MARK: - Safe Listening

    private func commitSafeListening() {
        let mode: MessageMdrV2EnableDisable = safeListeningPreviewMode.desired ? .ENABLE : .DISABLE

        if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_1) {
            queueCommand(SafeListeningSetParamSL(type: .SAFE_LISTENING_HBS_1, safeListeningMode: mode, previewMode: .DISABLE), type: .dataMdrNo2)
        } else if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_2) {
            queueCommand(SafeListeningSetParamSL(type: .SAFE_LISTENING_HBS_2, safeListeningMode: mode, previewMode: .DISABLE), type: .dataMdrNo2)
        } else if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_TWS_1) {
            queueCommand(SafeListeningSetParamSL(type: .SAFE_LISTENING_TWS_1, safeListeningMode: mode, previewMode: .DISABLE), type: .dataMdrNo2)
        } else if support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_TWS_2) {
            queueCommand(SafeListeningSetParamSL(type: .SAFE_LISTENING_TWS_2, safeListeningMode: mode, previewMode: .DISABLE), type: .dataMdrNo2)
        }
        safeListeningPreviewMode.commit()
    }
}
