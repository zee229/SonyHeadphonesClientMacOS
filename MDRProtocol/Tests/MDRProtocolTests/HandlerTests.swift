import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Helper

/// Serialize a command struct, pack it as a framed packet, inject into mock transport, and poll.
private func injectAndPoll<T: MDRSerializable>(
    _ hp: MDRHeadphones,
    _ mock: MockTransport,
    _ response: T,
    type: MDRDataType = .dataMdr
) -> Int {
    var writer = DataWriter()
    response.serialize(to: &writer)
    mock.receiveQueue.append(mdrPackCommand(type: type, seq: 0, payload: writer.data))
    return hp.pollEvents()
}

private func makeHP() -> (MDRHeadphones, MockTransport) {
    let mock = MockTransport()
    let hp = MDRHeadphones(transport: mock)
    return (hp, mock)
}

/// Create an HP with T1 support functions set
private func makeHPWithSupport(_ functions: [MessageMdrV2FunctionType_Table1]) -> (MDRHeadphones, MockTransport) {
    let (hp, mock) = makeHP()
    for f in functions {
        hp.support.table1Functions[Int(f.rawValue)] = true
    }
    return (hp, mock)
}

/// Create an HP with T2 support functions set
private func makeHPWithT2Support(_ functions: [MessageMdrV2FunctionType_Table2]) -> (MDRHeadphones, MockTransport) {
    let (hp, mock) = makeHP()
    for f in functions {
        hp.support.table2Functions[Int(f.rawValue)] = true
    }
    return (hp, mock)
}

/// Pump the poll loop, auto-injecting ACKs for sent commands until the queue drains.
/// Stops early if the task completes (isReady becomes true) to avoid consuming taskResult.
private func drainQueue(_ hp: MDRHeadphones, _ mock: MockTransport) {
    for _ in 0..<500 {
        if hp.isReady { return }
        let sentBefore = mock.sentData.count
        let _ = hp.pollEvents()
        if hp.isReady { return }
        if mock.sentData.count > sentBefore {
            mock.receiveQueue.append(mdrPackCommand(type: .ack, seq: 1, payload: Data()))
        }
    }
}

/// Inject an ACK packet for the most recently sent command.
private func injectACK(_ mock: MockTransport) {
    mock.receiveQueue.append(mdrPackCommand(type: .ack, seq: 1, payload: Data()))
}

// MARK: - T1 Common Status Handler

@Suite("Handler: CommonStatus")
struct HandlerCommonStatusTests {
    @Test func audioCodec() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, CommonStatusAudioCodec(
            command: .COMMON_RET_STATUS,
            type: .AUDIO_CODEC,
            audioCodec: .LDAC
        ))
        #expect(event == MDREvent.codec.rawValue)
        #expect(hp.audioCodec == .LDAC)
    }

    @Test func audioCodecSBC() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, CommonStatusAudioCodec(
            command: .COMMON_NTFY_STATUS,
            type: .AUDIO_CODEC,
            audioCodec: .SBC
        ))
        #expect(event == MDREvent.codec.rawValue)
        #expect(hp.audioCodec == .SBC)
    }
}

// MARK: - T1 NC/ASM Handler

@Suite("Handler: NcAsmParam")
struct HandlerNcAsmParamTests {
    @Test func dualModeSeamless() {
        let (hp, mock) = makeHPWithSupport([.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT])
        let event = injectAndPoll(hp, mock, NcAsmParamModeNcDualModeSwitchAsmSeamless(
            command: .NCASM_RET_PARAM,
            type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS,
            valueChangeStatus: .UNDER_CHANGING,
            ncAsmTotalEffect: .ON,
            ncAsmMode: .NC,
            ambientSoundMode: .VOICE,
            ambientSoundLevelValue: 15
        ))
        #expect(event == MDREvent.ncAsmParam.rawValue)
        #expect(hp.ncAsmEnabled.current == true)
        #expect(hp.ncAsmMode.current == .NC)
        #expect(hp.ncAsmFocusOnVoice.current == true)
        #expect(hp.ncAsmAmbientLevel.current == 15)
    }

    @Test func dualModeSeamlessOff() {
        let (hp, mock) = makeHPWithSupport([.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT])
        let event = injectAndPoll(hp, mock, NcAsmParamModeNcDualModeSwitchAsmSeamless(
            command: .NCASM_NTFY_PARAM,
            type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS,
            valueChangeStatus: .CHANGED,
            ncAsmTotalEffect: .OFF,
            ncAsmMode: .ASM,
            ambientSoundMode: .NORMAL,
            ambientSoundLevelValue: 5
        ))
        #expect(event == MDREvent.ncAsmParam.rawValue)
        #expect(hp.ncAsmEnabled.current == false)
        #expect(hp.ncAsmMode.current == .ASM)
        #expect(hp.ncAsmFocusOnVoice.current == false)
        #expect(hp.ncAsmAmbientLevel.current == 5)
    }

    @Test func dualModeSeamlessNa() {
        let (hp, mock) = makeHPWithSupport([.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT_NOISE_ADAPTATION])
        let event = injectAndPoll(hp, mock, NcAsmParamModeNcDualModeSwitchAsmSeamlessNa(
            command: .NCASM_RET_PARAM,
            type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA,
            valueChangeStatus: .UNDER_CHANGING,
            ncAsmTotalEffect: .ON,
            ncAsmMode: .NC,
            ambientSoundMode: .VOICE,
            ambientSoundLevelValue: 10,
            noiseAdaptiveOnOffValue: .ON,
            noiseAdaptiveSensitivitySettings: .HIGH
        ))
        #expect(event == MDREvent.ncAsmParam.rawValue)
        #expect(hp.ncAsmEnabled.current == true)
        #expect(hp.ncAsmAutoAsmEnabled.current == true)
        #expect(hp.ncAsmNoiseAdaptiveSensitivity.current == .HIGH)
    }

    @Test func asmSeamless() {
        let (hp, mock) = makeHPWithSupport([.AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT])
        let event = injectAndPoll(hp, mock, NcAsmParamAsmSeamless(
            command: .NCASM_RET_PARAM,
            type: .ASM_SEAMLESS,
            valueChangeStatus: .UNDER_CHANGING,
            ncAsmTotalEffect: .ON,
            ambientSoundMode: .NORMAL,
            ambientSoundLevelValue: 20
        ))
        #expect(event == MDREvent.ncAsmParam.rawValue)
        #expect(hp.ncAsmEnabled.current == true)
        #expect(hp.ncAsmFocusOnVoice.current == false)
        #expect(hp.ncAsmAmbientLevel.current == 20)
    }

    @Test func ncAmbToggle() {
        let (hp, mock) = makeHPWithSupport([.AMBIENT_SOUND_CONTROL_MODE_SELECT])
        let event = injectAndPoll(hp, mock, NcAsmParamNcAmbToggle(
            command: .NCASM_RET_PARAM,
            type: .NC_AMB_TOGGLE,
            function: .NC_ASM_OFF
        ))
        #expect(event == MDREvent.ncAsmButtonMode.rawValue)
        #expect(hp.ncAsmButtonFunction.current == .NC_ASM_OFF)
    }

    @Test func requiresSupport() {
        let (hp, mock) = makeHP() // no support set
        let event = injectAndPoll(hp, mock, NcAsmParamModeNcDualModeSwitchAsmSeamless(
            command: .NCASM_RET_PARAM,
            type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS,
            valueChangeStatus: .UNDER_CHANGING,
            ncAsmTotalEffect: .ON,
            ncAsmMode: .NC,
            ambientSoundMode: .VOICE,
            ambientSoundLevelValue: 15
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }
}

// MARK: - T1 Power Param Handler

@Suite("Handler: PowerParam")
struct HandlerPowerParamTests {
    @Test func autoPowerOff() {
        let (hp, mock) = makeHPWithSupport([.AUTO_POWER_OFF])
        let event = injectAndPoll(hp, mock, PowerParamAutoPowerOff(
            command: .POWER_RET_PARAM,
            type: .AUTO_POWER_OFF,
            currentPowerOffElements: .POWER_OFF_IN_30_MIN,
            lastSelectPowerOffElements: .POWER_OFF_IN_30_MIN
        ))
        #expect(event == MDREvent.autoPowerOffParam.rawValue)
        #expect(hp.powerAutoOff.current == .POWER_OFF_IN_30_MIN)
    }

    @Test func autoPowerOffWithWearingDetection() {
        let (hp, mock) = makeHPWithSupport([.AUTO_POWER_OFF_WITH_WEARING_DETECTION])
        let event = injectAndPoll(hp, mock, PowerParamAutoPowerOffWithWearingDetection(
            command: .POWER_RET_PARAM,
            type: .AUTO_POWER_OFF_WEARING_DETECTION,
            currentPowerOffElements: .POWER_OFF_IN_15_MIN,
            lastSelectPowerOffElements: .POWER_OFF_DISABLE
        ))
        #expect(event == MDREvent.autoPowerOffParam.rawValue)
        #expect(hp.powerAutoOffWearingDetection.current == .POWER_OFF_IN_15_MIN)
    }

    @Test func requiresSupport() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PowerParamAutoPowerOff(
            command: .POWER_RET_PARAM,
            type: .AUTO_POWER_OFF,
            currentPowerOffElements: .POWER_OFF_IN_30_MIN,
            lastSelectPowerOffElements: .POWER_OFF_IN_30_MIN
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }
}

// MARK: - T1 Play Param Handler

@Suite("Handler: PlayParam")
struct HandlerPlayParamTests {
    @Test func playbackMetadata() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PlayParamPlaybackControllerName(
            command: .PLAY_RET_PARAM,
            type: .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
            playbackNames: [
                PlaybackName(playbackNameStatus: .UNSETTLED, playbackName: PrefixedString("My Song")),
                PlaybackName(playbackNameStatus: .UNSETTLED, playbackName: PrefixedString("My Album")),
                PlaybackName(playbackNameStatus: .UNSETTLED, playbackName: PrefixedString("My Artist")),
                PlaybackName(playbackNameStatus: .UNSETTLED, playbackName: PrefixedString("")),
            ]
        ))
        #expect(event == MDREvent.playbackMetadata.rawValue)
        #expect(hp.playTrackTitle == "My Song")
        #expect(hp.playTrackAlbum == "My Album")
        #expect(hp.playTrackArtist == "My Artist")
    }

    @Test func playbackVolume() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PlayParamPlaybackControllerVolume(
            command: .PLAY_RET_PARAM,
            type: .MUSIC_VOLUME,
            volumeValue: 25
        ))
        #expect(event == MDREvent.playbackVolume.rawValue)
        #expect(hp.playVolume.current == 25)
    }
}

// MARK: - T1 Playback Status Handler

@Suite("Handler: PlaybackStatus")
struct HandlerPlaybackStatusTests {
    @Test func playPause() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PlayStatusPlaybackController(
            command: .PLAY_RET_STATUS,
            type: .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
            status: .ENABLE,
            playbackStatus: .PLAY,
            musicCallStatus: .MUSIC
        ))
        #expect(event == MDREvent.playbackPlayPause.rawValue)
        #expect(hp.playPause == .PLAY)
    }

    @Test func pause() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PlayStatusPlaybackController(
            command: .PLAY_NTFY_STATUS,
            type: .PLAYBACK_CONTROL_WITH_CALL_VOLUME_ADJUSTMENT,
            status: .ENABLE,
            playbackStatus: .PAUSE,
            musicCallStatus: .MUSIC
        ))
        #expect(event == MDREvent.playbackPlayPause.rawValue)
        #expect(hp.playPause == .PAUSE)
    }
}

// MARK: - T1 General Setting Capability Handler

@Suite("Handler: GsCapability")
struct HandlerGsCapabilityTests {
    @Test func generalSetting1() {
        let (hp, mock) = makeHP()
        let info = GsSettingInfo(
            stringFormat: .RAW_NAME,
            subject: PrefixedString("Wide Area Tap"),
            summary: PrefixedString("Enable wide area tap detection")
        )
        let event = injectAndPoll(hp, mock, GsRetCapability(
            command: .GENERAL_SETTING_RET_CAPABILITY,
            type: .GENERAL_SETTING1,
            settingType: .BOOLEAN_TYPE,
            settingInfo: info
        ))
        #expect(event == MDREvent.generalSetting1.rawValue)
        #expect(hp.gsCapability1.type == .BOOLEAN_TYPE)
        #expect(hp.gsCapability1.value.subject.value == "Wide Area Tap")
    }

    @Test func generalSetting2() {
        let (hp, mock) = makeHP()
        let info = GsSettingInfo(
            stringFormat: .RAW_NAME,
            subject: PrefixedString("Test"),
            summary: PrefixedString("Summary")
        )
        let event = injectAndPoll(hp, mock, GsRetCapability(
            command: .GENERAL_SETTING_RET_CAPABILITY,
            type: .GENERAL_SETTING2,
            settingType: .BOOLEAN_TYPE,
            settingInfo: info
        ))
        #expect(event == MDREvent.generalSetting2.rawValue)
    }

    @Test func generalSetting3() {
        let (hp, mock) = makeHP()
        let info = GsSettingInfo(stringFormat: .RAW_NAME, subject: PrefixedString("S3"), summary: PrefixedString(""))
        let event = injectAndPoll(hp, mock, GsRetCapability(
            command: .GENERAL_SETTING_RET_CAPABILITY,
            type: .GENERAL_SETTING3,
            settingType: .BOOLEAN_TYPE,
            settingInfo: info
        ))
        #expect(event == MDREvent.generalSetting3.rawValue)
    }

    @Test func generalSetting4() {
        let (hp, mock) = makeHP()
        let info = GsSettingInfo(stringFormat: .RAW_NAME, subject: PrefixedString("S4"), summary: PrefixedString(""))
        let event = injectAndPoll(hp, mock, GsRetCapability(
            command: .GENERAL_SETTING_RET_CAPABILITY,
            type: .GENERAL_SETTING4,
            settingType: .BOOLEAN_TYPE,
            settingInfo: info
        ))
        #expect(event == MDREvent.generalSetting4.rawValue)
    }
}

// MARK: - T1 General Setting Param Handler

@Suite("Handler: GsParam")
struct HandlerGsParamTests {
    @Test func gsParam1Boolean() {
        let (hp, mock) = makeHP()
        let base = GsParamBase(
            command: .GENERAL_SETTING_RET_PARAM,
            type: .GENERAL_SETTING1,
            settingType: .BOOLEAN_TYPE
        )
        let event = injectAndPoll(hp, mock, GsParamBoolean(
            base: base,
            settingValue: .ON
        ))
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.gsParamBool1.current == true)
    }

    @Test func gsParam2BooleanOff() {
        let (hp, mock) = makeHP()
        let base = GsParamBase(
            command: .GENERAL_SETTING_NTFY_PARAM,
            type: .GENERAL_SETTING2,
            settingType: .BOOLEAN_TYPE
        )
        let event = injectAndPoll(hp, mock, GsParamBoolean(
            base: base,
            settingValue: .OFF
        ))
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.gsParamBool2.current == false)
    }
}

// MARK: - T1 Audio Handlers

@Suite("Handler: AudioCapability")
struct HandlerAudioCapabilityTests {
    @Test func upscalingType() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        let event = injectAndPoll(hp, mock, AudioRetCapabilityUpscaling(
            command: .AUDIO_RET_CAPABILITY,
            type: .UPSCALING,
            upscalingType: .DSEE_ULTIMATE
        ))
        #expect(event == MDREvent.upscalingMode.rawValue)
        #expect(hp.upscalingType == .DSEE_ULTIMATE)
    }
}

@Suite("Handler: AudioStatus")
struct HandlerAudioStatusTests {
    @Test func upscalingAvailable() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        let event = injectAndPoll(hp, mock, AudioStatusCommon(
            command: .AUDIO_RET_STATUS,
            type: .UPSCALING,
            status: .ENABLE
        ))
        #expect(event == MDREvent.upscalingMode.rawValue)
        #expect(hp.upscalingAvailable == true)
    }

    @Test func upscalingNotAvailable() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        let event = injectAndPoll(hp, mock, AudioStatusCommon(
            command: .AUDIO_RET_STATUS,
            type: .UPSCALING,
            status: .DISABLE
        ))
        #expect(event == MDREvent.upscalingMode.rawValue)
        #expect(hp.upscalingAvailable == false)
    }
}

@Suite("Handler: AudioParam")
struct HandlerAudioParamTests {
    @Test func connectionMode() {
        let (hp, mock) = makeHPWithSupport([.CONNECTION_MODE_SOUND_QUALITY_CONNECTION_QUALITY])
        let event = injectAndPoll(hp, mock, AudioParamConnection(
            command: .AUDIO_RET_PARAM,
            type: .CONNECTION_MODE,
            settingValue: .CONNECTION_QUALITY_PRIOR
        ))
        #expect(event == MDREvent.connectionMode.rawValue)
        #expect(hp.audioPriorityMode.current == .CONNECTION_QUALITY_PRIOR)
    }

    @Test func upscalingEnabled() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        let event = injectAndPoll(hp, mock, AudioParamUpscaling(
            command: .AUDIO_RET_PARAM,
            type: .UPSCALING,
            settingValue: .AUTO
        ))
        #expect(event == MDREvent.upscalingMode.rawValue)
        #expect(hp.upscalingEnabled.current == true)
    }

    @Test func upscalingDisabled() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        let event = injectAndPoll(hp, mock, AudioParamUpscaling(
            command: .AUDIO_RET_PARAM,
            type: .UPSCALING,
            settingValue: .OFF
        ))
        #expect(event == MDREvent.upscalingMode.rawValue)
        #expect(hp.upscalingEnabled.current == false)
    }

    @Test func bgmMode() {
        let (hp, mock) = makeHPWithSupport([.LISTENING_OPTION])
        let event = injectAndPoll(hp, mock, AudioParamBGMMode(
            command: .AUDIO_RET_PARAM,
            type: .BGM_MODE,
            onOffSettingValue: .ENABLE,
            targetRoomSize: .MIDDLE
        ))
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.bgmModeEnabled.current == true)
        #expect(hp.bgmModeRoomSize.current == .MIDDLE)
    }

    @Test func upmixCinema() {
        let (hp, mock) = makeHPWithSupport([.LISTENING_OPTION])
        let event = injectAndPoll(hp, mock, AudioParamUpmixCinema(
            command: .AUDIO_RET_PARAM,
            type: .UPMIX_CINEMA,
            onOffSettingValue: .ENABLE
        ))
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.upmixCinemaEnabled.current == true)
    }
}

// MARK: - T1 System Param Handler

@Suite("Handler: SystemParam")
struct HandlerSystemParamTests {
    @Test func autoPause() {
        let (hp, mock) = makeHPWithSupport([.PLAYBACK_CONTROL_BY_WEARING_REMOVING_HEADPHONE_ON_OFF])
        let event = injectAndPoll(hp, mock, SystemParamCommon(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .PLAYBACK_CONTROL_BY_WEARING),
            settingValue: .ENABLE
        ))
        #expect(event == MDREvent.autoPause.rawValue)
        #expect(hp.autoPauseEnabled.current == true)
    }

    @Test func autoPauseDisabled() {
        let (hp, mock) = makeHPWithSupport([.PLAYBACK_CONTROL_BY_WEARING_REMOVING_HEADPHONE_ON_OFF])
        let event = injectAndPoll(hp, mock, SystemParamCommon(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .PLAYBACK_CONTROL_BY_WEARING),
            settingValue: .DISABLE
        ))
        #expect(event == MDREvent.autoPause.rawValue)
        #expect(hp.autoPauseEnabled.current == false)
    }

    @Test func assignableSettings() {
        let (hp, mock) = makeHPWithSupport([.ASSIGNABLE_SETTING])
        let event = injectAndPoll(hp, mock, SystemParamAssignableSettings(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .ASSIGNABLE_SETTINGS),
            presets: PodArray<UInt8>([
                Preset.AMBIENT_SOUND_CONTROL.rawValue,
                Preset.VOLUME_CONTROL.rawValue
            ])
        ))
        #expect(event == MDREvent.touchFunction.rawValue)
        #expect(hp.touchFunctionLeft.current == .AMBIENT_SOUND_CONTROL)
        #expect(hp.touchFunctionRight.current == .VOLUME_CONTROL)
    }

    @Test func speakToChat() {
        let (hp, mock) = makeHPWithSupport([.SMART_TALKING_MODE_TYPE2])
        let event = injectAndPoll(hp, mock, SystemParamSmartTalking(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .SMART_TALKING_MODE_TYPE2),
            onOffValue: .ENABLE,
            previewModeOnOffValue: .DISABLE
        ))
        #expect(event == MDREvent.speakToChatEnabled.rawValue)
        #expect(hp.speakToChatEnabled.current == true)
    }

    @Test func headGesture() {
        let (hp, mock) = makeHPWithSupport([.HEAD_GESTURE_ON_OFF_TRAINING])
        let event = injectAndPoll(hp, mock, SystemParamCommon(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .HEAD_GESTURE_ON_OFF),
            settingValue: .ENABLE
        ))
        #expect(event == MDREvent.headGesture.rawValue)
        #expect(hp.headGestureEnabled.current == true)
    }
}

// MARK: - T1 System Ext Param Handler

@Suite("Handler: SystemExtParam")
struct HandlerSystemExtParamTests {
    @Test func speakToChatMode2() {
        let (hp, mock) = makeHPWithSupport([.SMART_TALKING_MODE_TYPE2])
        let event = injectAndPoll(hp, mock, SystemExtParamSmartTalkingMode2(
            base: SystemExtBase(command: .SYSTEM_RET_EXT_PARAM, type: .SMART_TALKING_MODE_TYPE2),
            detectSensitivity: .HIGH,
            modeOffTime: .SLOW
        ))
        #expect(event == MDREvent.speakToChatParam.rawValue)
        #expect(hp.speakToChatDetectSensitivity.current == .HIGH)
        #expect(hp.speakToModeOutTime.current == .SLOW)
    }
}

// MARK: - T1 EQ/EBB Handlers

@Suite("Handler: EqEbbStatus")
struct HandlerEqEbbStatusTests {
    @Test func eqAvailableOn() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, EqEbbStatusOnOff(
            command: .EQEBB_RET_STATUS,
            type: .PRESET_EQ,
            status: .ON
        ))
        #expect(event == MDREvent.equalizerAvailable.rawValue)
        #expect(hp.eqAvailable.current == true)
    }

    @Test func eqAvailableOff() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, EqEbbStatusOnOff(
            command: .EQEBB_RET_STATUS,
            type: .PRESET_EQ,
            status: .OFF
        ))
        #expect(event == MDREvent.equalizerAvailable.rawValue)
        #expect(hp.eqAvailable.current == false)
    }
}

@Suite("Handler: EqEbbParam")
struct HandlerEqEbbParamTests {
    @Test func eqPresetNoBands() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, EqEbbParamEq(
            command: .EQEBB_RET_PARAM,
            type: .PRESET_EQ,
            presetId: .BRIGHT,
            bands: PodArray<UInt8>([])
        ))
        #expect(event == MDREvent.equalizerParam.rawValue)
        #expect(hp.eqPresetId.current == .BRIGHT)
    }

    @Test func eq6Bands() {
        let (hp, mock) = makeHP()
        // clearBass=12 (raw), 5 bands: 8,10,12,14,16 (raw)
        // Expected: clearBass = 12-10 = 2, bands = [-2, 0, 2, 4, 6]
        let event = injectAndPoll(hp, mock, EqEbbParamEq(
            command: .EQEBB_RET_PARAM,
            type: .PRESET_EQ,
            presetId: .CUSTOM,
            bands: PodArray<UInt8>([12, 8, 10, 12, 14, 16])
        ))
        #expect(event == MDREvent.equalizerParam.rawValue)
        #expect(hp.eqPresetId.current == .CUSTOM)
        #expect(hp.eqClearBass.current == 2)
        #expect(hp.eqConfig.current == [-2, 0, 2, 4, 6])
    }

    @Test func eq10Bands() {
        let (hp, mock) = makeHP()
        // 10 bands all at raw value 6 → offset 6 → 0
        let rawBands: [UInt8] = Array(repeating: 6, count: 10)
        let event = injectAndPoll(hp, mock, EqEbbParamEq(
            command: .EQEBB_RET_PARAM,
            type: .PRESET_EQ,
            presetId: .CUSTOM,
            bands: PodArray<UInt8>(rawBands)
        ))
        #expect(event == MDREvent.equalizerParam.rawValue)
        #expect(hp.eqClearBass.current == 0)
        #expect(hp.eqConfig.current == Array(repeating: 0, count: 10))
    }

    @Test func eq10BandsVaryingValues() {
        let (hp, mock) = makeHP()
        // raw: 0,2,4,6,8,10,12,4,2,0 → offset -6 each → -6,-4,-2,0,2,4,6,-2,-4,-6
        let event = injectAndPoll(hp, mock, EqEbbParamEq(
            command: .EQEBB_RET_PARAM,
            type: .PRESET_EQ,
            presetId: .CUSTOM,
            bands: PodArray<UInt8>([0, 2, 4, 6, 8, 10, 12, 4, 2, 0])
        ))
        #expect(event == MDREvent.equalizerParam.rawValue)
        #expect(hp.eqConfig.current == [-6, -4, -2, 0, 2, 4, 6, -2, -4, -6])
    }
}

// MARK: - T1 Alert Handler

@Suite("Handler: AlertParam")
struct HandlerAlertParamTests {
    @Test func fixedMessagePositiveNegative() {
        let (hp, mock) = makeHPWithSupport([.FIXED_MESSAGE])
        let event = injectAndPoll(hp, mock, AlertNotifyParamFixedMessage(
            command: .ALERT_NTFY_PARAM,
            type: .FIXED_MESSAGE,
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .POSITIVE_NEGATIVE
        ))
        #expect(event == MDREvent.alert.rawValue)
        #expect(hp.lastAlertMessage == .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE)
    }

    @Test func fixedMessageNonPositiveNegativeIgnored() {
        let (hp, mock) = makeHPWithSupport([.FIXED_MESSAGE])
        let event = injectAndPoll(hp, mock, AlertNotifyParamFixedMessage(
            command: .ALERT_NTFY_PARAM,
            type: .FIXED_MESSAGE,
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .CONFIRMATION_ONLY
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }
}

// MARK: - T1 Log Param Handler

@Suite("Handler: LogParam")
struct HandlerLogParamTests {
    @Test func jsonMessage() {
        let (hp, mock) = makeHP()
        // Build raw data: [command_byte, log_type=0x00, non_zero_byte, prefixed_string]
        let jsonStr = "{\"key\":\"value\"}"
        let strBytes = Array(jsonStr.utf8)
        var raw = Data()
        raw.append(T1Command.LOG_NTFY_PARAM.rawValue) // command
        raw.append(0x00)                                // logType
        raw.append(UInt8(strBytes.count))               // PrefixedString length byte
        raw.append(contentsOf: strBytes)                // string data

        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: raw))
        let event = hp.pollEvents()
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.lastDeviceJSONMessage == jsonStr)
    }

    @Test func interactionMessage() {
        let (hp, mock) = makeHP()
        let msg = "tap_left"
        let msgBytes = Array(msg.utf8)
        var raw = Data()
        raw.append(T1Command.LOG_NTFY_PARAM.rawValue) // command
        raw.append(0x01)                                // logType = interaction
        raw.append(0x00)                                // padding
        raw.append(0x00)                                // padding
        raw.append(contentsOf: msgBytes)                // message data

        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: raw))
        let event = hp.pollEvents()
        #expect(event == MDREvent.interaction.rawValue)
        #expect(hp.lastInteractionMessage == msg)
    }
}

// MARK: - T2 Voice Guidance Handler

@Suite("Handler: VoiceGuidanceParam")
struct HandlerVoiceGuidanceTests {
    @Test func voiceGuidanceEnabled() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, VoiceGuidanceParamSettingMtk(
            command: .VOICE_GUIDANCE_RET_PARAM,
            type: .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH,
            settingValue: .ON
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.voiceGuidanceEnable.rawValue)
        #expect(hp.voiceGuidanceEnabled.current == true)
    }

    @Test func voiceGuidanceDisabled() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, VoiceGuidanceParamSettingMtk(
            command: .VOICE_GUIDANCE_RET_PARAM,
            type: .MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH,
            settingValue: .OFF
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.voiceGuidanceEnable.rawValue)
        #expect(hp.voiceGuidanceEnabled.current == false)
    }

    @Test func voiceGuidanceVolume() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, VoiceGuidanceParamVolume(
            command: .VOICE_GUIDANCE_RET_PARAM,
            type: .VOLUME,
            volumeValue: 15
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.voiceGuidanceVolume.rawValue)
        #expect(hp.voiceGuidanceVolume.current == 15)
    }
}

// MARK: - T2 Peripheral Status Handler

@Suite("Handler: PeripheralStatus")
struct HandlerPeripheralStatusTests {
    @Test func pairingModeEnabled() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PeripheralStatusPairingDeviceManagementCommon(
            command: .PERI_RET_STATUS,
            type: .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
            btMode: .INQUIRY_SCAN_MODE,
            enableDisableStatus: .ENABLE
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.bluetoothMode.rawValue)
        #expect(hp.pairingMode.current == true)
    }

    @Test func pairingModeDisabled() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PeripheralStatusPairingDeviceManagementCommon(
            command: .PERI_RET_STATUS,
            type: .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
            btMode: .INQUIRY_SCAN_MODE,
            enableDisableStatus: .DISABLE
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.bluetoothMode.rawValue)
        #expect(hp.pairingMode.current == false)
    }

    @Test func pairingModeWithClassOfDevice() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, PeripheralStatusPairingDeviceManagementCommon(
            command: .PERI_NTFY_STATUS,
            type: .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE,
            btMode: .INQUIRY_SCAN_MODE,
            enableDisableStatus: .ENABLE
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.bluetoothMode.rawValue)
        #expect(hp.pairingMode.current == true)
    }
}

// MARK: - T2 Peripheral Notify Extended Param Handler

@Suite("Handler: PeripheralNotifyExtended")
struct HandlerPeripheralNotifyExtendedTests {
    @Test func sourceSwitchControl() {
        let (hp, mock) = makeHP()
        let macData = Data("AA:BB:CC:DD:EE:FF".utf8)
        let event = injectAndPoll(hp, mock, PeripheralNotifyExtendedParamSourceSwitchControl(
            command: .PERI_NTFY_EXTENDED_PARAM,
            type: .SOURCE_SWITCH_CONTROL,
            result: .SUCCESS,
            targetBdAddress: macData
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.multipointSwitch.rawValue)
        #expect(hp.multipointDeviceMac.current == "AA:BB:CC:DD:EE:FF")
    }
}

// MARK: - T2 Peripheral Param Handler

@Suite("Handler: PeripheralParam")
struct HandlerPeripheralParamTests {
    @Test func pairedDevicesClassicBt() {
        let (hp, mock) = makeHP()
        let mac1 = Data("AA:BB:CC:DD:EE:01".utf8)
        let mac2 = Data("AA:BB:CC:DD:EE:02".utf8)
        let dev1 = PeripheralDeviceInfo(
            btDeviceAddress: mac1,
            connectedStatus: 1,
            btFriendlyName: PrefixedString("Phone")
        )
        let dev2 = PeripheralDeviceInfo(
            btDeviceAddress: mac2,
            connectedStatus: 0,
            btFriendlyName: PrefixedString("Laptop")
        )
        let event = injectAndPoll(hp, mock, PeripheralParamPairingDeviceManagementClassicBt(
            command: .PERI_RET_PARAM,
            type: .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT,
            deviceList: MDRArray([dev1, dev2]),
            playbackDevice: 1
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.connectedDevices.rawValue)
        #expect(hp.pairedDevices.count == 2)
        #expect(hp.pairedDevices[0].name == "Phone")
        #expect(hp.pairedDevices[0].connected == true)
        #expect(hp.pairedDevices[1].name == "Laptop")
        #expect(hp.pairedDevices[1].connected == false)
        #expect(hp.multipointDeviceMac.current == "AA:BB:CC:DD:EE:01")
    }

    @Test func pairedDevicesWithClassOfDevice() {
        let (hp, mock) = makeHP()
        let mac1 = Data("AA:BB:CC:DD:EE:01".utf8)
        let dev1 = PeripheralDeviceInfoWithBluetoothClassOfDevice(
            btDeviceAddress: mac1,
            connectedStatus: 1,
            bluetoothClassOfDevice: Int24BE(0x240404),
            btFriendlyName: PrefixedString("Phone")
        )
        let event = injectAndPoll(hp, mock, PeripheralParamPairingDeviceManagementWithBluetoothClassOfDevice(
            command: .PERI_RET_PARAM,
            type: .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE,
            deviceList: MDRArray([dev1]),
            playbackDevice: 1
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.connectedDevices.rawValue)
        #expect(hp.pairedDevices.count == 1)
        #expect(hp.pairedDevices[0].name == "Phone")
        #expect(hp.pairedDevices[0].connected == true)
    }
}

// MARK: - T2 Safe Listening Handler

@Suite("Handler: SafeListening")
struct HandlerSafeListeningTests {
    @Test func safeListeningPreviewOn() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, SafeListeningNotifyParamSL(
            command: .SAFE_LISTENING_NTFY_PARAM,
            type: .SAFE_LISTENING_HBS_1,
            safeListeningMode: .ENABLE,
            previewMode: .ENABLE
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.safeListeningParam.rawValue)
        #expect(hp.safeListeningPreviewMode.current == true)
    }

    @Test func safeListeningPreviewOff() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, SafeListeningNotifyParamSL(
            command: .SAFE_LISTENING_NTFY_PARAM,
            type: .SAFE_LISTENING_TWS_2,
            safeListeningMode: .ENABLE,
            previewMode: .DISABLE
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.safeListeningParam.rawValue)
        #expect(hp.safeListeningPreviewMode.current == false)
    }

    @Test func soundPressure() {
        let (hp, mock) = makeHP()
        let event = injectAndPoll(hp, mock, SafeListeningRetExtendedParam(
            command: .SAFE_LISTENING_RET_EXTENDED_PARAM,
            inquiredType: .SAFE_LISTENING_HBS_1,
            levelPerPeriod: 78,
            errorCause: .NOT_PLAYING
        ), type: .dataMdrNo2)
        #expect(event == MDREvent.soundPressure.rawValue)
        #expect(hp.safeListeningSoundPressure == 78)
    }
}

// MARK: - Handler Branch Coverage

@Suite("Handler: NcAsmBranches")
struct HandlerNcAsmBranchTests {
    @Test func asmSeamlessWithoutSupport() {
        let (hp, mock) = makeHP() // no AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT
        let event = injectAndPoll(hp, mock, NcAsmParamAsmSeamless(
            command: .NCASM_RET_PARAM,
            type: .ASM_SEAMLESS,
            valueChangeStatus: .UNDER_CHANGING,
            ncAsmTotalEffect: .ON,
            ambientSoundMode: .NORMAL,
            ambientSoundLevelValue: 10
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }

    @Test func ncAmbToggleWithoutSupport() {
        let (hp, mock) = makeHP() // no AMBIENT_SOUND_CONTROL_MODE_SELECT
        let event = injectAndPoll(hp, mock, NcAsmParamNcAmbToggle(
            command: .NCASM_RET_PARAM,
            type: .NC_AMB_TOGGLE,
            function: .NC_ASM_OFF
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }

    @Test func unknownNcAsmType() {
        let (hp, _) = makeHP()
        // NC_ON_OFF (0x01) is a valid NcAsmInquiredType but not handled by any switch case
        let result = hp.handleCommandV2T1(Data([T1Command.NCASM_RET_PARAM.rawValue, NcAsmInquiredType.NC_ON_OFF.rawValue]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: PowerBranches")
struct HandlerPowerBranchTests {
    @Test func autoPowerOffWithoutSupport() {
        let (hp, mock) = makeHP() // no AUTO_POWER_OFF support
        let event = injectAndPoll(hp, mock, PowerParamAutoPowerOff(
            command: .POWER_RET_PARAM,
            type: .AUTO_POWER_OFF,
            currentPowerOffElements: .POWER_OFF_IN_30_MIN,
            lastSelectPowerOffElements: .POWER_OFF_IN_30_MIN
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: PlaybackStatusBranches")
struct HandlerPlaybackStatusBranchTests {
    @Test func unknownPlaybackType() {
        let (hp, _) = makeHP()
        // PLAY_MODE (0x40) is valid PlayInquiredType but not handled
        let result = hp.handleCommandV2T1(Data([T1Command.PLAY_RET_STATUS.rawValue, PlayInquiredType.PLAY_MODE.rawValue]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: EqEbbBranches")
struct HandlerEqEbbBranchTests {
    @Test func unexpectedBandCount() {
        let (hp, mock) = makeHP()
        // EQ with 3 bands — not 0, 6, or 10 → falls through to unhandled
        let event = injectAndPoll(hp, mock, EqEbbParamEq(
            command: .EQEBB_RET_PARAM,
            type: .PRESET_EQ,
            presetId: .CUSTOM,
            bands: PodArray<UInt8>([10, 11, 12])
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: LogBranches")
struct HandlerLogBranchTests {
    @Test func logType0ShortData() {
        let (hp, _) = makeHP()
        // logType 0x00, data[2] is 0, but data.count < 4 → unhandled
        let result = hp.handleCommandV2T1(Data([T1Command.LOG_NTFY_PARAM.rawValue, 0x00, 0x00]))
        #expect(result == MDREvent.unhandled.rawValue)
    }

    @Test func logType1InteractionMessage() {
        let (hp, _) = makeHP()
        // logType 0x01, data.count > 4 → interaction event
        var payload: [UInt8] = [T1Command.LOG_NTFY_PARAM.rawValue, 0x01, 0x00, 0x00]
        payload.append(contentsOf: "hello".utf8)
        let result = hp.handleCommandV2T1(Data(payload))
        #expect(result == MDREvent.interaction.rawValue)
        #expect(hp.lastInteractionMessage == "hello")
    }

    @Test func logType1TooShort() {
        let (hp, _) = makeHP()
        // logType 0x01, but data.count <= 4 → falls through to unhandled
        let result = hp.handleCommandV2T1(Data([T1Command.LOG_NTFY_PARAM.rawValue, 0x01, 0x00, 0x00]))
        #expect(result == MDREvent.unhandled.rawValue)
    }

    @Test func logTypeUnknown() {
        let (hp, _) = makeHP()
        // logType 0x02 → default case → unhandled
        let result = hp.handleCommandV2T1(Data([T1Command.LOG_NTFY_PARAM.rawValue, 0x02, 0x00, 0x00]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: AlertBranches")
struct HandlerAlertBranchTests {
    @Test func alertWithoutSupport() {
        let (hp, mock) = makeHP() // no FIXED_MESSAGE support
        let event = injectAndPoll(hp, mock, AlertNotifyParamFixedMessage(
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .POSITIVE_NEGATIVE
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }

    @Test func alertNonPositiveNegativeAction() {
        let (hp, mock) = makeHPWithSupport([.FIXED_MESSAGE])
        let event = injectAndPoll(hp, mock, AlertNotifyParamFixedMessage(
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .CONFIRMATION_ONLY
        ))
        #expect(event == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: VoiceGuidanceBranches")
struct HandlerVoiceGuidanceBranchTests {
    @Test func unsupportedVoiceGuidanceType() {
        let (hp, _) = makeHP()
        // ONLY_ON_OFF_SETTING (0x03) is valid but not handled by any case
        let result = hp.handleCommandV2T2(Data([T2Command.VOICE_GUIDANCE_RET_PARAM.rawValue, VoiceGuidanceInquiredType.ONLY_ON_OFF_SETTING.rawValue]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: PeripheralStatusBranches")
struct HandlerPeripheralStatusBranchTests {
    @Test func unsupportedPeripheralType() {
        let (hp, _) = makeHP()
        // SOURCE_SWITCH_CONTROL (0x01) is valid but not handled by peripheral status
        let result = hp.handleCommandV2T2(Data([T2Command.PERI_RET_STATUS.rawValue, PeripheralInquiredType.SOURCE_SWITCH_CONTROL.rawValue]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

@Suite("Handler: SafeListeningParamBranches")
struct HandlerSafeListeningParamBranchTests {
    @Test func safeVolumeControlTypeUnhandled() {
        let (hp, _) = makeHP()
        // SAFE_VOLUME_CONTROL (0x04) hits the default branch
        let result = hp.handleCommandV2T2(Data([T2Command.SAFE_LISTENING_NTFY_PARAM.rawValue, SafeListeningInquiredType.SAFE_VOLUME_CONTROL.rawValue]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

// MARK: - Edge Cases

@Suite("Handler: EdgeCases")
struct HandlerEdgeCaseTests {
    @Test func emptyDataReturnsUnhandled() {
        let (hp, _) = makeHP()
        let result = hp.handleCommandV2T1(Data())
        #expect(result == MDREvent.unhandled.rawValue)
    }

    @Test func unknownCommandByteReturnsUnhandled() {
        let (hp, _) = makeHP()
        let result = hp.handleCommandV2T1(Data([0xFF, 0x00]))
        #expect(result == MDREvent.unhandled.rawValue)
    }

    @Test func shortDataReturnsUnhandled() {
        let (hp, _) = makeHP()
        // Valid command byte but insufficient data
        let result = hp.handleCommandV2T1(Data([T1Command.NCASM_RET_PARAM.rawValue]))
        #expect(result == MDREvent.unhandled.rawValue)
    }

    @Test func emptyT2DataReturnsUnhandled() {
        let (hp, _) = makeHP()
        let result = hp.handleCommandV2T2(Data())
        #expect(result == MDREvent.unhandled.rawValue)
    }

    @Test func unknownT2CommandByteReturnsUnhandled() {
        let (hp, _) = makeHP()
        let result = hp.handleCommandV2T2(Data([0xFF, 0x00]))
        #expect(result == MDREvent.unhandled.rawValue)
    }
}

// MARK: - RequestInit Tests

/// Helper to decode sent commands from mock transport.
/// Handles multiple packed commands concatenated in a single sentData entry.
private func decodeSentCommands(_ mock: MockTransport) -> [(type: MDRDataType, data: Data)] {
    var results: [(type: MDRDataType, data: Data)] = []
    for sent in mock.sentData {
        var remaining = sent
        while !remaining.isEmpty {
            guard let startIdx = remaining.firstIndex(of: kStartMarker) else { break }
            let searchStart = remaining.index(after: startIdx)
            guard searchStart < remaining.endIndex,
                  let endIdx = remaining[searchStart...].firstIndex(of: kEndMarker) else { break }
            let cmdData = Data(remaining[startIdx...endIdx])
            let (result, unpacked) = mdrUnpackCommand(cmdData)
            if result == .ok, let cmd = unpacked {
                results.append((type: cmd.type, data: cmd.data))
            }
            remaining = Data(remaining[remaining.index(after: endIdx)...])
        }
    }
    return results
}

@Suite("RequestInit")
struct RequestInitTests {
    @Test func initSendsProtocolInfoFirst() {
        let (hp, mock) = makeHP()
        hp.requestInitV2()

        // First poll sends the commands
        let _ = hp.pollEvents()
        #expect(hp.isReady == false) // task is running, waiting for protocolInfo awaiter

        // Verify ConnectGetProtocolInfo was sent
        let cmds = decodeSentCommands(mock)
        #expect(cmds.count >= 1)
        #expect(cmds[0].type == .dataMdr)
        #expect(cmds[0].data.first == T1Command.CONNECT_GET_PROTOCOL_INFO.rawValue)
    }

    @Test func initCompletesAfterHandshake() {
        let (hp, mock) = makeHP()
        hp.requestInitV2()

        // Drain queue: sends ConnectGetProtocolInfo, ACK'd
        drainQueue(hp, mock)

        // Inject protocol info DATA response (T1 only, no T2)
        let protoResp = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .DISABLE
        )
        var w1 = DataWriter()
        protoResp.serialize(to: &w1)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: w1.data))
        let _ = hp.pollEvents() // process protocol info → queues phase 2a commands

        // Still need support function
        #expect(hp.isReady == false)

        // Drain queue: sends CapInfo, DevInfo x3, SupportFunc, all ACK'd
        drainQueue(hp, mock)

        // Inject support function DATA response (empty)
        let supResp = ConnectRetSupportFunction(supportFunctions: [])
        var w2 = DataWriter()
        supResp.serialize(to: &w2)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: w2.data))
        let _ = hp.pollEvents() // process support → queues phase 2b commands

        // Drain queue: all phase 2b commands ACK'd → task completes
        drainQueue(hp, mock)

        let event = hp.pollEvents()
        #expect(event == MDREvent.taskInitOK.rawValue)
        #expect(hp.isReady == true)
    }

    @Test func initWithTable2() {
        let (hp, mock) = makeHP()
        hp.requestInitV2()

        // Drain queue: sends ConnectGetProtocolInfo, ACK'd
        drainQueue(hp, mock)

        // Protocol info with T2
        let protoResp = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var w1 = DataWriter()
        protoResp.serialize(to: &w1)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: w1.data))
        let _ = hp.pollEvents()

        // Drain queue: sends CapInfo, DevInfo x3, SupportFunc, all ACK'd
        drainQueue(hp, mock)

        // T1 support function
        let supResp1 = ConnectRetSupportFunction(supportFunctions: [])
        var w2 = DataWriter()
        supResp1.serialize(to: &w2)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: w2.data))
        let _ = hp.pollEvents()

        // Drain queue: sends T2ConnectGetSupportFunction, ACK'd
        drainQueue(hp, mock)

        // Still waiting for T2 support function DATA
        #expect(hp.isReady == false)

        // T2 support function
        let supResp2 = T2ConnectRetSupportFunction(supportFunctions: [])
        var w3 = DataWriter()
        supResp2.serialize(to: &w3)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdrNo2, seq: 0, payload: w3.data))
        let _ = hp.pollEvents()

        // Drain queue: all phase 2 commands ACK'd → task completes
        drainQueue(hp, mock)

        let event = hp.pollEvents()
        #expect(event == MDREvent.taskInitOK.rawValue)
    }
}

// MARK: - RequestSync Tests

@Suite("RequestSync")
struct RequestSyncTests {
    @Test func syncCompletesImmediately() {
        let (hp, _) = makeHP()
        hp.requestSyncV2()
        let event = hp.pollEvents()
        #expect(event == MDREvent.taskSyncOK.rawValue)
        #expect(hp.isReady == true)
    }

    @Test func syncSendsBatteryCommand() {
        let (hp, mock) = makeHPWithSupport([.BATTERY_LEVEL_INDICATOR])
        hp.requestSyncV2()
        let _ = hp.pollEvents() // send + complete

        let cmds = decodeSentCommands(mock)
        let hasBatteryCmd = cmds.contains { $0.data.first == T1Command.POWER_GET_STATUS.rawValue }
        #expect(hasBatteryCmd == true)
    }

    @Test func syncSendsLRBattery() {
        let (hp, mock) = makeHPWithSupport([.LEFT_RIGHT_BATTERY_LEVEL_INDICATOR])
        hp.requestSyncV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasBatteryCmd = cmds.contains { cmd in
            cmd.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            cmd.data.count >= 2 && cmd.data[1] == PowerInquiredType.LEFT_RIGHT_BATTERY.rawValue
        }
        #expect(hasBatteryCmd == true)
    }

    @Test func syncSendsSafeListeningT2() {
        let (hp, mock) = makeHPWithT2Support([.SAFE_LISTENING_HBS_1])
        hp.requestSyncV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSLCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasSLCmd == true)
    }
}

// MARK: - RequestCommit Tests

@Suite("RequestCommit")
struct RequestCommitTests {
    @Test func commitNoChanges() {
        let (hp, mock) = makeHP()
        hp.requestCommitV2()
        let event = hp.pollEvents()
        #expect(event == MDREvent.taskCommitOK.rawValue)
        // Only ACK-like data, no actual commands sent to mock
        let cmds = decodeSentCommands(mock)
        #expect(cmds.isEmpty)
    }

    @Test func commitNcAsm() {
        let (hp, mock) = makeHPWithSupport([.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT])
        hp.ncAsmEnabled.desired = true
        hp.ncAsmMode.desired = .ASM
        hp.ncAsmAmbientLevel.desired = 15
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasNcAsmCmd = cmds.contains { $0.data.first == T1Command.NCASM_SET_PARAM.rawValue }
        #expect(hasNcAsmCmd == true)
        #expect(hp.ncAsmEnabled.isDirty == false)
        #expect(hp.ncAsmMode.isDirty == false)
    }

    @Test func commitVolume() {
        let (hp, mock) = makeHP()
        hp.playVolume.desired = 20
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasVolumeCmd = cmds.contains { $0.data.first == T1Command.PLAY_SET_PARAM.rawValue }
        #expect(hasVolumeCmd == true)
        #expect(hp.playVolume.isDirty == false)
        #expect(hp.playVolume.current == 20)
    }

    @Test func commitPlayControl() {
        let (hp, mock) = makeHP()
        hp.playControl.desired = .PLAY
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPlayCmd = cmds.contains { $0.data.first == T1Command.PLAY_SET_STATUS.rawValue }
        #expect(hasPlayCmd == true)
        // After commit, playControl is reset to KEY_OFF
        #expect(hp.playControl.current == .KEY_OFF)
        #expect(hp.playControl.isDirty == false)
    }

    @Test func commitEqPreset() {
        let (hp, mock) = makeHP()
        hp.eqPresetId.desired = .BRIGHT
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasEqSetCmd = cmds.contains { $0.data.first == T1Command.EQEBB_SET_PARAM.rawValue }
        let hasEqGetCmd = cmds.contains { $0.data.first == T1Command.EQEBB_GET_PARAM.rawValue }
        #expect(hasEqSetCmd == true)
        #expect(hasEqGetCmd == true) // should request updated EQ after setting preset
        #expect(hp.eqPresetId.isDirty == false)
    }

    @Test func commitEqBands5() {
        let (hp, mock) = makeHP()
        hp.eqClearBass.desired = 2
        hp.eqConfig.desired = [0, 1, 2, 3, 4]
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let eqCmd = cmds.first { $0.data.first == T1Command.EQEBB_SET_PARAM.rawValue }
        #expect(eqCmd != nil)
        #expect(hp.eqConfig.isDirty == false)
        #expect(hp.eqClearBass.isDirty == false)
    }

    @Test func commitMultipointSwitch() {
        let (hp, mock) = makeHP()
        hp.multipointDeviceMac.desired = "AA:BB:CC:DD:EE:FF"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasMultipointCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasMultipointCmd == true)
        #expect(hp.multipointDeviceMac.isDirty == false)
    }

    @Test func commitMultipointInvalidMac() {
        let (hp, mock) = makeHP()
        hp.multipointDeviceMac.desired = "short"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        // Should not send any command, just overwrite to empty
        let cmds = decodeSentCommands(mock)
        let hasMultipointCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasMultipointCmd == false)
        #expect(hp.multipointDeviceMac.current == "")
    }

    @Test func commitVoiceGuidance() {
        let (hp, mock) = makeHP()
        hp.voiceGuidanceEnabled.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasVGCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasVGCmd == true)
        #expect(hp.voiceGuidanceEnabled.isDirty == false)
    }

    @Test func commitSpeakToChat() {
        let (hp, mock) = makeHPWithSupport([.SMART_TALKING_MODE_TYPE2])
        hp.speakToChatEnabled.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSTCCmd = cmds.contains { $0.data.first == T1Command.SYSTEM_SET_PARAM.rawValue }
        #expect(hasSTCCmd == true)
        #expect(hp.speakToChatEnabled.isDirty == false)
    }

    @Test func commitConnectionMode() {
        let (hp, mock) = makeHPWithSupport([.CONNECTION_MODE_SOUND_QUALITY_CONNECTION_QUALITY])
        hp.audioPriorityMode.desired = .CONNECTION_QUALITY_PRIOR
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasAudioCmd = cmds.contains { $0.data.first == T1Command.AUDIO_SET_PARAM.rawValue }
        #expect(hasAudioCmd == true)
        #expect(hp.audioPriorityMode.isDirty == false)
    }

    @Test func commitShutdown() {
        let (hp, mock) = makeHPWithSupport([.POWER_OFF])
        hp.shutdown.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPowerOffCmd = cmds.contains { $0.data.first == T1Command.POWER_SET_STATUS.rawValue }
        #expect(hasPowerOffCmd == true)
    }

    @Test func commitTouchFunctions() {
        let (hp, mock) = makeHPWithSupport([.ASSIGNABLE_SETTING])
        hp.touchFunctionLeft.desired = .VOLUME_CONTROL
        hp.touchFunctionRight.desired = .AMBIENT_SOUND_CONTROL
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSystemCmd = cmds.contains { $0.data.first == T1Command.SYSTEM_SET_PARAM.rawValue }
        #expect(hasSystemCmd == true)
        #expect(hp.touchFunctionLeft.isDirty == false)
        #expect(hp.touchFunctionRight.isDirty == false)
    }

    @Test func commitPairingMode() {
        let (hp, mock) = makeHPWithT2Support([.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT])
        hp.pairingMode.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPeriCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasPeriCmd == true)
        #expect(hp.pairingMode.isDirty == false)
    }

    @Test func commitNcAmbToggle() {
        let (hp, mock) = makeHPWithSupport([.AMBIENT_SOUND_CONTROL_MODE_SELECT])
        hp.ncAsmButtonFunction.desired = .NC_ASM
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasNcAsmCmd = cmds.contains { $0.data.first == T1Command.NCASM_SET_PARAM.rawValue }
        #expect(hasNcAsmCmd == true)
        #expect(hp.ncAsmButtonFunction.isDirty == false)
    }

    @Test func commitSpeakToChatSensitivityAndTimeout() {
        let (hp, mock) = makeHPWithSupport([.SMART_TALKING_MODE_TYPE2])
        hp.speakToChatDetectSensitivity.desired = .HIGH
        hp.speakToModeOutTime.desired = .SLOW
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasExtCmd = cmds.contains { $0.data.first == T1Command.SYSTEM_SET_EXT_PARAM.rawValue }
        #expect(hasExtCmd == true)
        #expect(hp.speakToChatDetectSensitivity.isDirty == false)
        #expect(hp.speakToModeOutTime.isDirty == false)
    }

    @Test func commitBGMMode() {
        let (hp, mock) = makeHPWithSupport([.LISTENING_OPTION])
        hp.bgmModeEnabled.desired = true
        hp.bgmModeRoomSize.desired = .MIDDLE
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasAudioCmd = cmds.contains { $0.data.first == T1Command.AUDIO_SET_PARAM.rawValue }
        #expect(hasAudioCmd == true)
        #expect(hp.bgmModeEnabled.isDirty == false)
        #expect(hp.bgmModeRoomSize.isDirty == false)
    }

    @Test func commitUpmixCinema() {
        let (hp, mock) = makeHPWithSupport([.LISTENING_OPTION])
        hp.upmixCinemaEnabled.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasAudioCmd = cmds.contains { $0.data.first == T1Command.AUDIO_SET_PARAM.rawValue }
        #expect(hasAudioCmd == true)
        #expect(hp.upmixCinemaEnabled.isDirty == false)
    }

    @Test func commitDSEE() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        hp.upscalingEnabled.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasAudioCmd = cmds.contains { $0.data.first == T1Command.AUDIO_SET_PARAM.rawValue }
        #expect(hasAudioCmd == true)
        #expect(hp.upscalingEnabled.isDirty == false)
    }

    @Test func commitHeadGesture() {
        let (hp, mock) = makeHPWithSupport([.HEAD_GESTURE_ON_OFF_TRAINING])
        hp.headGestureEnabled.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSystemCmd = cmds.contains { $0.data.first == T1Command.SYSTEM_SET_PARAM.rawValue }
        #expect(hasSystemCmd == true)
        #expect(hp.headGestureEnabled.isDirty == false)
    }

    @Test func commitHeadGestureNotSentWithUpscalingSupport() {
        let (hp, mock) = makeHPWithSupport([.UPSCALING_AUTO_OFF])
        hp.headGestureEnabled.desired = true
        hp.requestCommitV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasHeadGestureCmd = cmds.contains {
            $0.data.first == T1Command.SYSTEM_SET_PARAM.rawValue &&
            $0.data.count >= 2 && $0.data[1] == SystemInquiredType.HEAD_GESTURE_ON_OFF.rawValue
        }
        #expect(hasHeadGestureCmd == false)
        #expect(hp.headGestureEnabled.isDirty == true)
    }

    @Test func commitAutoPowerOff() {
        let (hp, mock) = makeHPWithSupport([.AUTO_POWER_OFF])
        hp.powerAutoOff.desired = .POWER_OFF_IN_30_MIN
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPowerCmd = cmds.contains { $0.data.first == T1Command.POWER_SET_PARAM.rawValue }
        #expect(hasPowerCmd == true)
        #expect(hp.powerAutoOff.isDirty == false)
        #expect(hp.powerAutoOff.current == .POWER_OFF_IN_30_MIN)
    }

    @Test func commitAutoPowerOffWearingDetection() {
        let (hp, mock) = makeHPWithSupport([.AUTO_POWER_OFF_WITH_WEARING_DETECTION])
        hp.powerAutoOffWearingDetection.desired = .POWER_OFF_IN_15_MIN
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPowerCmd = cmds.contains { $0.data.first == T1Command.POWER_SET_PARAM.rawValue }
        #expect(hasPowerCmd == true)
        #expect(hp.powerAutoOffWearingDetection.isDirty == false)
    }

    @Test func commitAutoPause() {
        let (hp, mock) = makeHPWithSupport([.PLAYBACK_CONTROL_BY_WEARING_REMOVING_HEADPHONE_ON_OFF])
        hp.autoPauseEnabled.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSystemCmd = cmds.contains { $0.data.first == T1Command.SYSTEM_SET_PARAM.rawValue }
        #expect(hasSystemCmd == true)
        #expect(hp.autoPauseEnabled.isDirty == false)
    }

    @Test func commitVoiceGuidanceVolume() {
        let (hp, mock) = makeHPWithT2Support([
            .VOICE_GUIDANCE_SETTING_MTK_TRANSFER_WITHOUT_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH_AND_VOLUME_ADJUSTMENT
        ])
        hp.voiceGuidanceVolume.desired = 2
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasVGCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasVGCmd == true)
        #expect(hp.voiceGuidanceVolume.isDirty == false)
    }

    @Test func commitGsParamBool1() {
        let (hp, mock) = makeHPWithSupport([.GENERAL_SETTING_1])
        hp.gsParamBool1.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasGsCmd = cmds.contains { $0.data.first == T1Command.GENERAL_SETTING_SET_PARAM.rawValue }
        #expect(hasGsCmd == true)
        #expect(hp.gsParamBool1.isDirty == false)
    }

    @Test func commitGsParamBool2() {
        let (hp, mock) = makeHPWithSupport([.GENERAL_SETTING_2])
        hp.gsParamBool2.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasGsCmd = cmds.contains { $0.data.first == T1Command.GENERAL_SETTING_SET_PARAM.rawValue }
        #expect(hasGsCmd == true)
        #expect(hp.gsParamBool2.isDirty == false)
    }

    @Test func commitGsParamBool3() {
        let (hp, mock) = makeHPWithSupport([.GENERAL_SETTING_3])
        hp.gsParamBool3.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasGsCmd = cmds.contains { $0.data.first == T1Command.GENERAL_SETTING_SET_PARAM.rawValue }
        #expect(hasGsCmd == true)
        #expect(hp.gsParamBool3.isDirty == false)
    }

    @Test func commitGsParamBool4() {
        let (hp, mock) = makeHPWithSupport([.GENERAL_SETTING_4])
        hp.gsParamBool4.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasGsCmd = cmds.contains { $0.data.first == T1Command.GENERAL_SETTING_SET_PARAM.rawValue }
        #expect(hasGsCmd == true)
        #expect(hp.gsParamBool4.isDirty == false)
    }

    @Test func commitSafeListeningHBS1() {
        let (hp, mock) = makeHPWithT2Support([.SAFE_LISTENING_HBS_1])
        hp.safeListeningPreviewMode.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSLCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasSLCmd == true)
        #expect(hp.safeListeningPreviewMode.isDirty == false)
    }

    @Test func commitSafeListeningTWS2() {
        let (hp, mock) = makeHPWithT2Support([.SAFE_LISTENING_TWS_2])
        hp.safeListeningPreviewMode.desired = true
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSLCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasSLCmd == true)
        #expect(hp.safeListeningPreviewMode.isDirty == false)
    }

    @Test func commitDeviceConnect() {
        let (hp, mock) = makeHPWithT2Support([.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT])
        hp.pairedDeviceConnectMac.desired = "AA:BB:CC:DD:EE:FF"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPeriCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasPeriCmd == true)
        // After connect, MAC is overwritten to empty
        #expect(hp.pairedDeviceConnectMac.current == "")
        #expect(hp.pairedDeviceConnectMac.isDirty == false)
    }

    @Test func commitDeviceDisconnect() {
        let (hp, mock) = makeHPWithT2Support([.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT])
        hp.pairedDeviceDisconnectMac.desired = "AA:BB:CC:DD:EE:FF"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPeriCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasPeriCmd == true)
        #expect(hp.pairedDeviceDisconnectMac.current == "")
        #expect(hp.pairedDeviceDisconnectMac.isDirty == false)
    }

    @Test func commitDeviceUnpair() {
        let (hp, mock) = makeHPWithT2Support([.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT])
        hp.pairedDeviceUnpairMac.desired = "AA:BB:CC:DD:EE:FF"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPeriCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasPeriCmd == true)
        #expect(hp.pairedDeviceUnpairMac.current == "")
        #expect(hp.pairedDeviceUnpairMac.isDirty == false)
    }

    @Test func commitNcAsmWithNASupport() {
        let (hp, mock) = makeHPWithSupport([
            .MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT_NOISE_ADAPTATION
        ])
        hp.ncAsmEnabled.desired = true
        hp.ncAsmAutoAsmEnabled.desired = true
        hp.ncAsmNoiseAdaptiveSensitivity.desired = .HIGH
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasNcAsmCmd = cmds.contains { $0.data.first == T1Command.NCASM_SET_PARAM.rawValue }
        #expect(hasNcAsmCmd == true)
        #expect(hp.ncAsmAutoAsmEnabled.isDirty == false)
        #expect(hp.ncAsmNoiseAdaptiveSensitivity.isDirty == false)
    }

    @Test func commitNcAsmWithASMSeamlessSupport() {
        let (hp, mock) = makeHPWithSupport([.AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT])
        hp.ncAsmEnabled.desired = true
        hp.ncAsmFocusOnVoice.desired = true
        hp.ncAsmAmbientLevel.desired = 10
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasNcAsmCmd = cmds.contains { $0.data.first == T1Command.NCASM_SET_PARAM.rawValue }
        #expect(hasNcAsmCmd == true)
        #expect(hp.ncAsmEnabled.isDirty == false)
        #expect(hp.ncAsmFocusOnVoice.isDirty == false)
        #expect(hp.ncAsmAmbientLevel.isDirty == false)
    }

    @Test func commitEqBands10() {
        let (hp, mock) = makeHP()
        hp.eqConfig.desired = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasEqCmd = cmds.contains { $0.data.first == T1Command.EQEBB_SET_PARAM.rawValue }
        #expect(hasEqCmd == true)
        #expect(hp.eqConfig.isDirty == false)
    }

    @Test func commitEqBandsEmpty() {
        let (hp, mock) = makeHP()
        // Set eqConfig to empty but make it dirty by going non-default → empty
        hp.eqConfig.overwrite([1, 2, 3])
        hp.eqConfig.desired = []
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        // Empty bands should just commit without sending command
        #expect(hp.eqConfig.isDirty == false)
    }

    @Test func commitDeviceConnectWithClassOfDevice() {
        let (hp, mock) = makeHPWithT2Support([
            .PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE_CLASSIC_BT
        ])
        hp.pairedDeviceConnectMac.desired = "AA:BB:CC:DD:EE:FF"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPeriCmd = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasPeriCmd == true)
        #expect(hp.pairedDeviceConnectMac.current == "")
    }

    @Test func commitConnectionOpsWithNoSupport() {
        let (hp, mock) = makeHP() // No T2 support
        hp.pairedDeviceConnectMac.desired = "AA:BB:CC:DD:EE:FF"
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        // Without support, MAC should be overwritten to empty
        #expect(hp.pairedDeviceConnectMac.current == "")
        #expect(hp.pairedDeviceConnectMac.isDirty == false)
    }

    @Test func commitAudioPriorityMode() {
        let (hp, mock) = makeHPWithSupport([.CONNECTION_MODE_SOUND_QUALITY_CONNECTION_QUALITY])
        hp.audioPriorityMode.desired = .SOUND_QUALITY_PRIOR
        // Need to make it dirty - overwrite to different then set desired
        hp.audioPriorityMode.overwrite(.CONNECTION_QUALITY_PRIOR)
        hp.audioPriorityMode.desired = .SOUND_QUALITY_PRIOR
        hp.requestCommitV2()
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasAudioCmd = cmds.contains { $0.data.first == T1Command.AUDIO_SET_PARAM.rawValue }
        #expect(hasAudioCmd == true)
        #expect(hp.audioPriorityMode.isDirty == false)
    }
}
