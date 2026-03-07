import Foundation

// MARK: - T1 Command Handlers

extension MDRHeadphones {

    // MARK: Common Status

    func handleCommonStatusT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let inquiredType = CommonInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch inquiredType {
        case .AUDIO_CODEC:
            guard let res = try? CommonStatusAudioCodec.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            audioCodec = res.audioCodec
            return MDREvent.codec.rawValue
        default:
            return MDREvent.unhandled.rawValue
        }
    }

    // MARK: NC/ASM Param

    func handleNcAsmParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let inquiredType = NcAsmInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch inquiredType {
        case .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS:
            if support.contains(.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT) {
                guard let res = try? NcAsmParamModeNcDualModeSwitchAsmSeamless.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                ncAsmEnabled.overwrite(res.ncAsmTotalEffect == .ON)
                ncAsmMode.overwrite(res.ncAsmMode)
                ncAsmFocusOnVoice.overwrite(res.ambientSoundMode == .VOICE)
                ncAsmAmbientLevel.overwrite(Int(res.ambientSoundLevelValue))
                return MDREvent.ncAsmParam.rawValue
            }
        case .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA:
            if support.contains(.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT_NOISE_ADAPTATION) {
                guard let res = try? NcAsmParamModeNcDualModeSwitchAsmSeamlessNa.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                ncAsmEnabled.overwrite(res.ncAsmTotalEffect == .ON)
                ncAsmMode.overwrite(res.ncAsmMode)
                ncAsmFocusOnVoice.overwrite(res.ambientSoundMode == .VOICE)
                ncAsmAmbientLevel.overwrite(Int(res.ambientSoundLevelValue))
                ncAsmAutoAsmEnabled.overwrite(res.noiseAdaptiveOnOffValue == .ON)
                ncAsmNoiseAdaptiveSensitivity.overwrite(res.noiseAdaptiveSensitivitySettings)
                return MDREvent.ncAsmParam.rawValue
            }
        case .ASM_SEAMLESS:
            if support.contains(.AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT) {
                guard let res = try? NcAsmParamAsmSeamless.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                ncAsmEnabled.overwrite(res.ncAsmTotalEffect == .ON)
                ncAsmFocusOnVoice.overwrite(res.ambientSoundMode == .VOICE)
                ncAsmAmbientLevel.overwrite(Int(res.ambientSoundLevelValue))
                return MDREvent.ncAsmParam.rawValue
            }
        case .NC_AMB_TOGGLE:
            if support.contains(.AMBIENT_SOUND_CONTROL_MODE_SELECT) {
                guard let res = try? NcAsmParamNcAmbToggle.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                ncAsmButtonFunction.overwrite(res.function)
                return MDREvent.ncAsmButtonMode.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Power Param (Auto Power Off)

    func handlePowerParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let powerType = PowerInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch powerType {
        case .AUTO_POWER_OFF:
            if support.contains(.AUTO_POWER_OFF) {
                guard let res = try? PowerParamAutoPowerOff.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                powerAutoOff.overwrite(res.currentPowerOffElements)
                return MDREvent.autoPowerOffParam.rawValue
            }
        case .AUTO_POWER_OFF_WEARING_DETECTION:
            if support.contains(.AUTO_POWER_OFF_WITH_WEARING_DETECTION) {
                guard let res = try? PowerParamAutoPowerOffWithWearingDetection.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                powerAutoOffWearingDetection.overwrite(res.currentPowerOffElements)
                return MDREvent.autoPowerOffParam.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Play Param (Metadata + Volume)

    func handlePlayParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let playType = PlayInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch playType {
        case .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT:
            guard let res = try? PlayParamPlaybackControllerName.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            if res.playbackNames.count >= 3 {
                playTrackTitle = res.playbackNames[0].playbackName.value
                playTrackAlbum = res.playbackNames[1].playbackName.value
                playTrackArtist = res.playbackNames[2].playbackName.value
            }
            return MDREvent.playbackMetadata.rawValue
        case .MUSIC_VOLUME:
            guard let res = try? PlayParamPlaybackControllerVolume.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            playVolume.overwrite(Int(res.volumeValue))
            return MDREvent.playbackVolume.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Playback Status (Play/Pause)

    func handlePlaybackStatusT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let playType = PlayInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch playType {
        case .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT:
            guard let res = try? PlayStatusPlaybackController.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            playPause = res.playbackStatus
            return MDREvent.playbackPlayPause.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: General Setting Capability

    func handleGsCapabilityT1(_ data: Data) -> Int {
        var reader = DataReader(Data(data))
        guard let res = try? GsRetCapability.deserialize(from: &reader) else {
            return MDREvent.unhandled.rawValue
        }
        let cap = GsCapability(type: res.settingType, value: res.settingInfo)
        switch res.type {
        case .GENERAL_SETTING1:
            gsCapability1 = cap
            return MDREvent.generalSetting1.rawValue
        case .GENERAL_SETTING2:
            gsCapability2 = cap
            return MDREvent.generalSetting2.rawValue
        case .GENERAL_SETTING3:
            gsCapability3 = cap
            return MDREvent.generalSetting3.rawValue
        case .GENERAL_SETTING4:
            gsCapability4 = cap
            return MDREvent.generalSetting4.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: General Setting Param

    func handleGsParamT1(_ data: Data) -> Int {
        guard data.count >= 3 else { return MDREvent.unhandled.rawValue }
        var baseReader = DataReader(Data(data))
        guard let base = try? GsParamBase.deserialize(from: &baseReader) else {
            return MDREvent.unhandled.rawValue
        }

        func writeBoolean(_ prop: inout MDRProperty<Bool>) -> Int {
            switch base.settingType {
            case .BOOLEAN_TYPE:
                var reader = DataReader(Data(data))
                guard let res = try? GsParamBoolean.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                prop.overwrite(res.settingValue == .ON)
                return MDREvent.ok.rawValue
            default:
                return MDREvent.unhandled.rawValue
            }
        }

        switch base.type {
        case .GENERAL_SETTING1: return writeBoolean(&gsParamBool1)
        case .GENERAL_SETTING2: return writeBoolean(&gsParamBool2)
        case .GENERAL_SETTING3: return writeBoolean(&gsParamBool3)
        case .GENERAL_SETTING4: return writeBoolean(&gsParamBool4)
        default: break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Audio Capability

    func handleAudioCapabilityT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let audioType = AudioInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch audioType {
        case .UPSCALING:
            if support.contains(.UPSCALING_AUTO_OFF) {
                guard let res = try? AudioRetCapabilityUpscaling.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                upscalingType = res.upscalingType
                return MDREvent.upscalingMode.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Audio Status

    func handleAudioStatusT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let audioType = AudioInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch audioType {
        case .UPSCALING:
            if support.contains(.UPSCALING_AUTO_OFF) {
                guard let res = try? AudioStatusCommon.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                upscalingAvailable = res.status == .ENABLE
                return MDREvent.upscalingMode.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Audio Param

    func handleAudioParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let audioType = AudioInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch audioType {
        case .CONNECTION_MODE:
            if support.contains(.CONNECTION_MODE_SOUND_QUALITY_CONNECTION_QUALITY) {
                guard let res = try? AudioParamConnection.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                audioPriorityMode.overwrite(res.settingValue)
                return MDREvent.connectionMode.rawValue
            }
        case .UPSCALING:
            if support.contains(.UPSCALING_AUTO_OFF) {
                guard let res = try? AudioParamUpscaling.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                upscalingEnabled.overwrite(res.settingValue == .AUTO)
                return MDREvent.upscalingMode.rawValue
            }
        case .BGM_MODE:
            if support.contains(.LISTENING_OPTION) {
                guard let res = try? AudioParamBGMMode.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                bgmModeEnabled.overwrite(res.onOffSettingValue == .ENABLE)
                bgmModeRoomSize.overwrite(res.targetRoomSize)
                return MDREvent.ok.rawValue
            }
        case .UPMIX_CINEMA:
            if support.contains(.LISTENING_OPTION) {
                guard let res = try? AudioParamUpmixCinema.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                upmixCinemaEnabled.overwrite(res.onOffSettingValue == .ENABLE)
                return MDREvent.ok.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: System Param

    func handleSystemParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let systemType = SystemInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch systemType {
        case .PLAYBACK_CONTROL_BY_WEARING:
            if support.contains(.PLAYBACK_CONTROL_BY_WEARING_REMOVING_HEADPHONE_ON_OFF) {
                guard let res = try? SystemParamCommon.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                autoPauseEnabled.overwrite(res.settingValue == .ENABLE)
                return MDREvent.autoPause.rawValue
            }
        case .ASSIGNABLE_SETTINGS:
            if support.contains(.ASSIGNABLE_SETTING) {
                guard let res = try? SystemParamAssignableSettings.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                if res.presets.value.count == 2 {
                    touchFunctionLeft.overwrite(Preset(rawValue: res.presets.value[0]) ?? .NO_FUNCTION)
                    touchFunctionRight.overwrite(Preset(rawValue: res.presets.value[1]) ?? .NO_FUNCTION)
                }
                return MDREvent.touchFunction.rawValue
            }
        case .SMART_TALKING_MODE_TYPE2:
            if support.contains(.SMART_TALKING_MODE_TYPE2) {
                guard let res = try? SystemParamSmartTalking.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                speakToChatEnabled.overwrite(res.onOffValue == .ENABLE)
                return MDREvent.speakToChatEnabled.rawValue
            }
        case .HEAD_GESTURE_ON_OFF:
            if support.contains(.HEAD_GESTURE_ON_OFF_TRAINING) {
                guard let res = try? SystemParamCommon.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                headGestureEnabled.overwrite(res.settingValue == .ENABLE)
                return MDREvent.headGesture.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: System Ext Param

    func handleSystemExtParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let systemType = SystemInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch systemType {
        case .SMART_TALKING_MODE_TYPE2:
            if support.contains(.SMART_TALKING_MODE_TYPE2) {
                guard let res = try? SystemExtParamSmartTalkingMode2.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                speakToChatDetectSensitivity.overwrite(res.detectSensitivity)
                speakToModeOutTime.overwrite(res.modeOffTime)
                return MDREvent.speakToChatParam.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: EQ/EBB Status

    func handleEqEbbStatusT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let eqType = EqEbbInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch eqType {
        case .PRESET_EQ:
            guard let res = try? EqEbbStatusOnOff.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            eqAvailable.overwrite(res.status == .ON)
            return MDREvent.equalizerAvailable.rawValue
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: EQ/EBB Param

    func handleEqEbbParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let eqType = EqEbbInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch eqType {
        case .PRESET_EQ:
            guard let res = try? EqEbbParamEq.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            eqPresetId.overwrite(res.presetId)
            let bands = res.bands.value
            switch bands.count {
            case 0:
                return MDREvent.equalizerParam.rawValue
            case 6:
                eqClearBass.overwrite(Int(bands[0]) - 10)
                eqConfig.overwrite([
                    Int(bands[1]) - 10,
                    Int(bands[2]) - 10,
                    Int(bands[3]) - 10,
                    Int(bands[4]) - 10,
                    Int(bands[5]) - 10,
                ])
                return MDREvent.equalizerParam.rawValue
            case 10:
                eqClearBass.overwrite(0)
                eqConfig.overwrite((0..<10).map { Int(bands[$0]) - 6 })
                return MDREvent.equalizerParam.rawValue
            default:
                break
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Alert Param

    func handleAlertParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let alertType = AlertInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch alertType {
        case .FIXED_MESSAGE:
            if support.contains(.FIXED_MESSAGE) {
                guard let res = try? AlertNotifyParamFixedMessage.deserialize(from: &reader) else {
                    return MDREvent.unhandled.rawValue
                }
                if res.actionType == .POSITIVE_NEGATIVE {
                    lastAlertMessage = res.messageType
                    return MDREvent.alert.rawValue
                }
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }

    // MARK: Log Param

    func handleLogParamT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let logType = data[data.startIndex + 1]
        switch logType {
        case 0x00:
            // JSON message
            let offset: Int
            if data.count >= 3 && data[data.startIndex + 2] != 0 {
                offset = 2
            } else if data.count >= 4 {
                offset = 3
            } else {
                return MDREvent.unhandled.rawValue
            }
            var reader = DataReader(Data(data.dropFirst(offset)))
            guard let str = try? PrefixedString.read(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            lastDeviceJSONMessage = str.value
            return MDREvent.ok.rawValue
        case 0x01:
            // Interaction message
            if data.count > 4 {
                lastInteractionMessage = String(data: Data(data[(data.startIndex + 4)...]), encoding: .utf8) ?? ""
                return MDREvent.interaction.rawValue
            }
        default:
            break
        }
        return MDREvent.unhandled.rawValue
    }
}
