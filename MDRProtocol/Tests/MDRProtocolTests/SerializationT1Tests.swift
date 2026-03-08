import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Helper

/// Serialize → deserialize roundtrip and verify equality.
func roundtrip<T: MDRSerializable & Equatable>(_ value: T) throws -> T {
    var writer = DataWriter()
    value.serialize(to: &writer)
    var reader = DataReader(writer.data)
    return try T.deserialize(from: &reader)
}

/// Serialize and return raw bytes.
func serialize<T: MDRSerializable>(_ value: T) -> Data {
    var writer = DataWriter()
    value.serialize(to: &writer)
    return writer.data
}

// MARK: - Connect Tests

@Suite("T1 Connect Serialization")
struct T1ConnectSerializationTests {
    @Test func connectGetProtocolInfoRoundtrip() throws {
        let original = ConnectGetProtocolInfo()
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 2)
    }

    @Test func connectGetProtocolInfoBytes() {
        let data = serialize(ConnectGetProtocolInfo())
        #expect(data == Data([T1Command.CONNECT_GET_PROTOCOL_INFO.rawValue, ConnectInquiredType.FIXED_VALUE.rawValue]))
    }

    @Test func connectRetProtocolInfoRoundtrip() throws {
        let original = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(0x00020000),
            supportTable1Value: .ENABLE,
            supportTable2Value: .DISABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.protocolVersion.value == 0x00020000)
        #expect(restored.supportTable1Value == .ENABLE)
        #expect(restored.supportTable2Value == .DISABLE)
    }

    @Test func connectRetProtocolInfoBytes() {
        let data = serialize(ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        ))
        // command(1) + inquiredType(1) + protocolVersion(4) + table1(1) + table2(1) = 8
        #expect(data.count == 8)
        #expect(data[0] == T1Command.CONNECT_RET_PROTOCOL_INFO.rawValue)
    }

    @Test func connectGetCapabilityInfoRoundtrip() throws {
        let original = ConnectGetCapabilityInfo()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func connectRetCapabilityInfoRoundtrip() throws {
        let original = ConnectRetCapabilityInfo(
            capabilityCounter: 42,
            uniqueID: PrefixedString("ABC123")
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.capabilityCounter == 42)
        #expect(restored.uniqueID.value == "ABC123")
    }

    @Test func connectRetCapabilityInfoBytes() {
        let data = serialize(ConnectRetCapabilityInfo(
            capabilityCounter: 1,
            uniqueID: PrefixedString("Hi")
        ))
        // command(1) + inquiredType(1) + counter(1) + lenPrefix(1) + "Hi"(2) = 6
        #expect(data.count == 6)
    }

    @Test func connectGetDeviceInfoRoundtrip() throws {
        let original = ConnectGetDeviceInfo(deviceInfoType: .FW_VERSION)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.deviceInfoType == .FW_VERSION)
    }

    @Test func connectRetDeviceInfoModelNameRoundtrip() throws {
        let original = ConnectRetDeviceInfoModelName(
            value: PrefixedString("WH-1000XM5")
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.value.value == "WH-1000XM5")
    }

    @Test func connectRetDeviceInfoFwVersionRoundtrip() throws {
        let original = ConnectRetDeviceInfoFwVersion(
            value: PrefixedString("2.0.7")
        )
        let restored = try roundtrip(original)
        #expect(restored.value.value == "2.0.7")
    }

    @Test func connectRetDeviceInfoSeriesAndColorRoundtrip() throws {
        let original = ConnectRetDeviceInfoSeriesAndColor(
            series: .LINK_BUDS,
            color: .BLACK
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.series == .LINK_BUDS)
        #expect(restored.color == .BLACK)
    }

    @Test func connectGetSupportFunctionRoundtrip() throws {
        let original = ConnectGetSupportFunction()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func connectRetSupportFunctionRoundtrip() throws {
        let entries = [
            SupportFunctionEntry(rawFunction: 0x50, priority: 1),
            SupportFunctionEntry(rawFunction: 0x61, priority: 2),
        ]
        let original = ConnectRetSupportFunction(supportFunctions: entries)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.supportFunctions.count == 2)
        #expect(restored.supportFunctions[0].rawFunction == 0x50)
        #expect(restored.supportFunctions[1].priority == 2)
    }

    @Test func connectRetSupportFunctionBytes() {
        let original = ConnectRetSupportFunction(
            supportFunctions: [SupportFunctionEntry(rawFunction: 0x10, priority: 0)]
        )
        let data = serialize(original)
        // command(1) + inquiredType(1) + count(1) + 1*entry(2) = 5
        #expect(data.count == 5)
        #expect(data[2] == 1) // count
        #expect(data[3] == 0x10) // rawFunction
        #expect(data[4] == 0) // priority
    }

    @Test func connectRetSupportFunctionEmpty() throws {
        let original = ConnectRetSupportFunction(supportFunctions: [])
        let restored = try roundtrip(original)
        #expect(restored.supportFunctions.isEmpty)
    }
}

// MARK: - NcAsm Tests

@Suite("T1 NcAsm Serialization")
struct T1NcAsmSerializationTests {
    @Test func ncAsmGetParamRoundtrip() throws {
        let original = NcAsmGetParam(type: .MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 2)
    }

    @Test func ncAsmParamModeNcDualRoundtrip() throws {
        let original = NcAsmParamModeNcDualModeSwitchAsmSeamless(
            valueChangeStatus: .UNDER_CHANGING,
            ncAsmTotalEffect: .ON,
            ncAsmMode: .ASM,
            ambientSoundMode: .VOICE,
            ambientSoundLevelValue: 15
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.ncAsmMode == .ASM)
        #expect(restored.ambientSoundLevelValue == 15)
    }

    @Test func ncAsmParamModeNcDualBytes() {
        let data = serialize(NcAsmParamModeNcDualModeSwitchAsmSeamless(
            valueChangeStatus: .CHANGED,
            ncAsmTotalEffect: .ON,
            ncAsmMode: .NC,
            ambientSoundMode: .NORMAL,
            ambientSoundLevelValue: 0
        ))
        // command + type + valueChangeStatus + ncAsmTotalEffect + ncAsmMode + ambientSoundMode + level = 7
        #expect(data.count == 7)
    }

    @Test func ncAsmParamModeNcDualNaRoundtrip() throws {
        let original = NcAsmParamModeNcDualModeSwitchAsmSeamlessNa(
            valueChangeStatus: .CHANGED,
            ncAsmTotalEffect: .ON,
            ncAsmMode: .NC,
            ambientSoundMode: .NORMAL,
            ambientSoundLevelValue: 10,
            noiseAdaptiveOnOffValue: .ON,
            noiseAdaptiveSensitivitySettings: .HIGH
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.noiseAdaptiveOnOffValue == .ON)
        #expect(restored.noiseAdaptiveSensitivitySettings == .HIGH)
        #expect(serialize(original).count == 9) // 7 + 2 extra fields
    }

    @Test func ncAsmParamAsmOnOffRoundtrip() throws {
        let original = NcAsmParamAsmOnOff(
            valueChangeStatus: .CHANGED,
            ncAsmTotalEffect: .ON,
            ambientSoundMode: .VOICE,
            ambientSoundValue: .ON
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func ncAsmParamAsmSeamlessRoundtrip() throws {
        let original = NcAsmParamAsmSeamless(
            valueChangeStatus: .CHANGED,
            ncAsmTotalEffect: .OFF,
            ambientSoundMode: .NORMAL,
            ambientSoundLevelValue: 20
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.ambientSoundLevelValue == 20)
    }

    @Test func ncAsmParamNcAmbToggleRoundtrip() throws {
        let original = NcAsmParamNcAmbToggle(function: .NC_ASM_OFF)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 3)
    }
}

// MARK: - EqEbb Tests

@Suite("T1 EqEbb Serialization")
struct T1EqEbbSerializationTests {
    @Test func eqEbbGetStatusRoundtrip() throws {
        let original = EqEbbGetStatus(type: .PRESET_EQ)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func eqEbbGetParamRoundtrip() throws {
        let original = EqEbbGetParam(type: .EBB)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func eqEbbStatusOnOffRoundtrip() throws {
        let original = EqEbbStatusOnOff(status: .ON)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.status == .ON)
    }

    @Test func eqEbbStatusErrorCodeRoundtrip() throws {
        let original = EqEbbStatusErrorCode(
            value: .ENABLE,
            errors: PodArray([1, 2, 3])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.errors.value.count == 3)
    }

    @Test func eqEbbParamEqRoundtrip() throws {
        let bands: [UInt8] = [10, 8, 6, 8, 10]
        let original = EqEbbParamEq(
            presetId: .CUSTOM,
            bands: PodArray(bands)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.presetId == .CUSTOM)
        #expect(restored.bands.value == bands)
    }

    @Test func eqEbbParamEqBytes() {
        let data = serialize(EqEbbParamEq(
            presetId: .ROCK,
            bands: PodArray<UInt8>([5, 5, 5])
        ))
        // command(1) + type(1) + presetId(1) + count(1) + bands(3) = 7
        #expect(data.count == 7)
        #expect(data[2] == EqPresetId.ROCK.rawValue)
        #expect(data[3] == 3) // count
    }

    @Test func eqEbbParamEbbRoundtrip() throws {
        let original = EqEbbParamEbb(level: 42)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.level == 42)
    }

    @Test func eqEbbParamEqAndUltModeRoundtrip() throws {
        let original = EqEbbParamEqAndUltMode(
            presetId: .BRIGHT,
            eqUltModeStatus: .ULT_1,
            bandSteps: PodArray<UInt8>([1, 2, 3, 4, 5])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.eqUltModeStatus == .ULT_1)
    }

    @Test func eqEbbParamSoundEffectRoundtrip() throws {
        let original = EqEbbParamSoundEffect(soundEffectValue: .SOUND_EFFECT_OFF)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func eqEbbParamCustomEqRoundtrip() throws {
        let original = EqEbbParamCustomEq(bandSteps: PodArray<UInt8>([7, 8, 9]))
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.bandSteps.value == [7, 8, 9])
    }
}

// MARK: - Power Tests

@Suite("T1 Power Serialization")
struct T1PowerSerializationTests {
    @Test func powerGetStatusRoundtrip() throws {
        let original = PowerGetStatus(type: .LEFT_RIGHT_BATTERY)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 2)
    }

    @Test func powerRetStatusBatteryRoundtrip() throws {
        let original = PowerRetStatusBattery(
            batteryStatus: PowerBatteryStatus(batteryLevel: 85, chargingStatus: .CHARGING)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.batteryStatus.batteryLevel == 85)
        #expect(restored.batteryStatus.chargingStatus == .CHARGING)
    }

    @Test func powerRetStatusBatteryBytes() {
        let data = serialize(PowerRetStatusBattery(
            batteryStatus: PowerBatteryStatus(batteryLevel: 50, chargingStatus: .NOT_CHARGING)
        ))
        // command(1) + type(1) + level(1) + chargingStatus(1) = 4
        #expect(data.count == 4)
        #expect(data[0] == T1Command.POWER_RET_STATUS.rawValue)
        #expect(data[2] == 50) // battery level
        #expect(data[3] == BatteryChargingStatus.NOT_CHARGING.rawValue)
    }

    @Test func powerRetStatusLeftRightBatteryRoundtrip() throws {
        let original = PowerRetStatusLeftRightBattery(
            batteryStatus: PowerLeftRightBatteryStatus(
                leftBatteryLevel: 90,
                leftChargingStatus: .NOT_CHARGING,
                rightBatteryLevel: 80,
                rightChargingStatus: .CHARGING
            )
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.batteryStatus.leftBatteryLevel == 90)
        #expect(restored.batteryStatus.rightBatteryLevel == 80)
    }

    @Test func powerRetStatusCradleBatteryRoundtrip() throws {
        let original = PowerRetStatusCradleBattery(
            batteryStatus: PowerBatteryStatus(batteryLevel: 100, chargingStatus: .CHARGED)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func powerRetStatusBatteryThresholdRoundtrip() throws {
        let original = PowerRetStatusBatteryThreshold(
            batteryStatus: PowerBatteryThresholdStatus(
                batteryStatus: PowerBatteryStatus(batteryLevel: 60, chargingStatus: .NOT_CHARGING),
                batteryThreshold: 20
            )
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.batteryStatus.batteryThreshold == 20)
    }

    @Test func powerRetStatusLeftRightBatteryThresholdRoundtrip() throws {
        let original = PowerRetStatusLeftRightBatteryThreshold(
            batteryStatus: PowerLeftRightBatteryStatus(
                leftBatteryLevel: 70, leftChargingStatus: .CHARGING,
                rightBatteryLevel: 65, rightChargingStatus: .NOT_CHARGING
            ),
            leftBatteryThreshold: 15,
            rightBatteryThreshold: 10
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.leftBatteryThreshold == 15)
        #expect(restored.rightBatteryThreshold == 10)
        // command(1)+type(1)+LR battery(4)+thresholds(2) = 8
        #expect(serialize(original).count == 8)
    }

    @Test func powerSetStatusPowerOffRoundtrip() throws {
        let original = PowerSetStatusPowerOff()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func powerGetParamRoundtrip() throws {
        let original = PowerGetParam(type: .CARING_CHARGE)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func powerParamAutoPowerOffRoundtrip() throws {
        let original = PowerParamAutoPowerOff(
            currentPowerOffElements: .POWER_OFF_IN_30_MIN,
            lastSelectPowerOffElements: .POWER_OFF_IN_5_MIN
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.currentPowerOffElements == .POWER_OFF_IN_30_MIN)
    }

    @Test func powerParamSettingOnOffRoundtrip() throws {
        let original = PowerParamSettingOnOff(
            type: .CARING_CHARGE,
            onOffSetting: .ON
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.onOffSetting == .ON)
    }

    @Test func powerParamBatterySafeModeRoundtrip() throws {
        let original = PowerParamBatterySafeMode(
            onOffSettingValue: .ON,
            effectStatus: .OFF
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }
}

// MARK: - Common Tests

@Suite("T1 Common Serialization")
struct T1CommonSerializationTests {
    @Test func commonGetStatusRoundtrip() throws {
        let original = CommonGetStatus()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func commonStatusAudioCodecRoundtrip() throws {
        let original = CommonStatusAudioCodec(audioCodec: .LDAC)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.audioCodec == .LDAC)
        #expect(serialize(original).count == 3)
    }
}

// MARK: - Play Tests

@Suite("T1 Play Serialization")
struct T1PlaySerializationTests {
    @Test func getPlayParamRoundtrip() throws {
        let original = GetPlayParam()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func getPlayStatusRoundtrip() throws {
        let original = GetPlayStatus()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func playStatusPlaybackControllerRoundtrip() throws {
        let original = PlayStatusPlaybackController(
            status: .ENABLE,
            playbackStatus: .PLAY,
            musicCallStatus: .MUSIC
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.playbackStatus == .PLAY)
        #expect(serialize(original).count == 5)
    }

    @Test func playStatusSetPlaybackControllerRoundtrip() throws {
        let original = PlayStatusSetPlaybackController(
            status: .ENABLE,
            control: .PLAY
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func playParamVolumeRoundtrip() throws {
        let original = PlayParamPlaybackControllerVolume(volumeValue: 75)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.volumeValue == 75)
        #expect(serialize(original).count == 3)
    }

    @Test func playParamVolumeWithMuteRoundtrip() throws {
        let original = PlayParamPlaybackControllerVolumeWithMute(
            volumeValue: 50,
            muteSetting: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.muteSetting == .ENABLE)
    }

    @Test func playParamPlayModeRoundtrip() throws {
        let original = PlayParamPlayMode(playMode: .SHUFFLE_ALL)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func playbackNameRoundtrip() throws {
        let name = PlaybackName(
            playbackNameStatus: .SETTLED,
            playbackName: PrefixedString("Spotify")
        )
        var writer = DataWriter()
        name.write(to: &writer)
        var reader = DataReader(writer.data)
        let restored = try PlaybackName.read(from: &reader)
        #expect(restored == name)
        #expect(restored.playbackName.value == "Spotify")
    }

    @Test func playParamPlaybackControllerNameRoundtrip() throws {
        let names = [
            PlaybackName(playbackNameStatus: .SETTLED, playbackName: PrefixedString("App1")),
            PlaybackName(playbackNameStatus: .NOTHING, playbackName: PrefixedString("")),
            PlaybackName(playbackNameStatus: .UNSETTLED, playbackName: PrefixedString("")),
            PlaybackName(playbackNameStatus: .SETTLED, playbackName: PrefixedString("App4")),
        ]
        let original = PlayParamPlaybackControllerName(playbackNames: names)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.playbackNames.count == 4)
        #expect(restored.playbackNames[0].playbackName.value == "App1")
    }

    @Test func playStatusCommonRoundtrip() throws {
        let original = PlayStatusCommon(status: .DISABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }
}

// MARK: - Audio Tests

@Suite("T1 Audio Serialization")
struct T1AudioSerializationTests {
    @Test func audioGetCapabilityRoundtrip() throws {
        let original = AudioGetCapability()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func audioGetParamRoundtrip() throws {
        let original = AudioGetParam(type: .CONNECTION_MODE)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func audioParamConnectionRoundtrip() throws {
        let original = AudioParamConnection(settingValue: .SOUND_QUALITY_PRIOR)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 3)
    }

    @Test func audioParamBGMModeRoundtrip() throws {
        let original = AudioParamBGMMode(
            onOffSettingValue: .ENABLE,
            targetRoomSize: .LARGE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }

    @Test func audioParamUpmixCinemaRoundtrip() throws {
        let original = AudioParamUpmixCinema(onOffSettingValue: .ENABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func audioSetParamConnectionModeClassicLeAudioRoundtrip() throws {
        let original = AudioSetParamConnectionModeClassicAudioLeAudio(
            settingValue: .CONNECTION_QUALITY_PRIOR,
            alertConfirmation: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }
}

// MARK: - Alert Tests

@Suite("T1 Alert Serialization")
struct T1AlertSerializationTests {
    @Test func alertGetStatusRoundtrip() throws {
        let original = AlertGetStatus()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func alertStatusLEAudioAlertNotificationRoundtrip() throws {
        let original = AlertStatusLEAudioAlertNotification(leAudioAlertStatus: .ENABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 3)
    }

    @Test func alertSetStatusFixedMessageRoundtrip() throws {
        let original = AlertSetStatusFixedMessage(status: .DISABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func alertSetParamFixedMessageRoundtrip() throws {
        let original = AlertSetParamFixedMessage(
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .POSITIVE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }
}

// MARK: - System Tests

@Suite("T1 System Serialization")
struct T1SystemSerializationTests {
    @Test func systemGetParamRoundtrip() throws {
        let original = SystemGetParam()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func systemParamCommonRoundtrip() throws {
        let original = SystemParamCommon(settingValue: .ENABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 3)
    }

    @Test func systemParamAssignableSettingsRoundtrip() throws {
        let original = SystemParamAssignableSettings(
            presets: PodArray<UInt8>([
                Preset.AMBIENT_SOUND_CONTROL.rawValue,
                Preset.VOLUME_CONTROL.rawValue,
            ])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.presets.value.count == 2)
    }

    @Test func systemGetExtParamRoundtrip() throws {
        let original = SystemGetExtParam()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }
}

// MARK: - GeneralSetting Tests

@Suite("T1 GeneralSetting Serialization")
struct T1GeneralSettingSerializationTests {
    @Test func gsGetCapabilityRoundtrip() throws {
        let original = GsGetCapability()
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 3)
    }

    @Test func gsGetParamRoundtrip() throws {
        let original = GsGetParam()
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func gsParamBooleanRoundtrip() throws {
        let original = GsParamBoolean(settingValue: .ON)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }

    @Test func gsParamListRoundtrip() throws {
        let original = GsParamList(currentElementIndex: 5)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.currentElementIndex == 5)
    }

    @Test func gsSettingInfoRoundtrip() throws {
        let info = GsSettingInfo(
            subject: PrefixedString("Test Setting"),
            summary: PrefixedString("Description")
        )
        var writer = DataWriter()
        info.write(to: &writer)
        var reader = DataReader(writer.data)
        let restored = try GsSettingInfo.read(from: &reader)
        #expect(restored == info)
        #expect(restored.subject.value == "Test Setting")
        #expect(restored.summary.value == "Description")
    }

    @Test func gsRetCapabilityRoundtrip() throws {
        let original = GsRetCapability(
            settingInfo: GsSettingInfo(
                subject: PrefixedString("NC"),
                summary: PrefixedString("Noise Cancel")
            )
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.settingInfo.subject.value == "NC")
    }
}

// MARK: - Additional System Tests

@Suite("T1 Additional System Serialization")
struct T1AdditionalSystemSerializationTests {
    @Test func systemParamSmartTalkingRoundtrip() throws {
        let original = SystemParamSmartTalking(
            base: SystemBase(command: .SYSTEM_SET_PARAM, type: .SMART_TALKING_MODE_TYPE1),
            onOffValue: .DISABLE,
            previewModeOnOffValue: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.onOffValue == .DISABLE)
        #expect(restored.previewModeOnOffValue == .ENABLE)
        // base(2) + onOff(1) + previewOnOff(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func systemParamVoiceAssistantSettingsRoundtrip() throws {
        let original = SystemParamVoiceAssistantSettings(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .VOICE_ASSISTANT_SETTINGS),
            voiceAssistant: .GOOGLE_ASSISTANT
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.voiceAssistant == .GOOGLE_ASSISTANT)
        // base(2) + voiceAssistant(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemParamWearingStatusDetectorRoundtrip() throws {
        let original = SystemParamWearingStatusDetector(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .WEARING_STATUS_DETECTOR),
            operationStatus: .DETECTION_STARTED,
            errorCode: .LEFT_CONNECTION_ERROR,
            numOfSelectedEarpieces: 3,
            indexOfCurrentDetection: 1,
            currentDetectingSeries: .HYBRID,
            earpieceSize: .M
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.operationStatus == .DETECTION_STARTED)
        #expect(restored.errorCode == .LEFT_CONNECTION_ERROR)
        #expect(restored.numOfSelectedEarpieces == 3)
        #expect(restored.indexOfCurrentDetection == 1)
        #expect(restored.currentDetectingSeries == .HYBRID)
        #expect(restored.earpieceSize == .M)
        // base(2) + 6 fields = 8
        #expect(serialize(original).count == 8)
    }

    @Test func systemParamEarpieceSelectionRoundtrip() throws {
        let original = SystemParamEarpieceSelection(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .EARPIECE_SELECTION),
            series: .POLYURETHANE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.series == .POLYURETHANE)
        // base(2) + series(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemParamCallSettingsRoundtrip() throws {
        let original = SystemParamCallSettings(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .CALL_SETTINGS),
            selfVoiceOnOff: .DISABLE,
            selfVoiceVolume: 5,
            callVoiceVolume: 10
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.selfVoiceOnOff == .DISABLE)
        #expect(restored.selfVoiceVolume == 5)
        #expect(restored.callVoiceVolume == 10)
        // base(2) + selfVoiceOnOff(1) + selfVoiceVolume(1) + callVoiceVolume(1) = 5
        #expect(serialize(original).count == 5)
    }

    @Test func systemParamAssignableSettingsWithLimitRoundtrip() throws {
        let original = SystemParamAssignableSettingsWithLimit(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .ASSIGNABLE_SETTINGS_WITH_LIMITATION),
            presets: PodArray<UInt8>([
                Preset.AMBIENT_SOUND_CONTROL.rawValue,
                Preset.PLAYBACK_CONTROL.rawValue,
                Preset.VOLUME_CONTROL.rawValue,
            ])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.presets.value.count == 3)
    }

    @Test func systemParamHeadGestureTrainingRoundtrip() throws {
        let original = SystemParamHeadGestureTraining(
            base: SystemBase(command: .SYSTEM_RET_PARAM, type: .HEAD_GESTURE_TRAINING),
            headGestureAction: .SWING
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.headGestureAction == .SWING)
        // base(2) + action(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemSetParamWearingStatusDetectorRoundtrip() throws {
        let original = SystemSetParamWearingStatusDetector(
            base: SystemBase(command: .SYSTEM_SET_PARAM, type: .WEARING_STATUS_DETECTOR),
            operation: .DETECTION_CANCEL,
            indexOfCurrentDetection: 2,
            currentDetectionSeries: .SOFT_FITTING_FOR_LINKBUDS_FIT,
            currentDetectionSize: .L
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.operation == .DETECTION_CANCEL)
        #expect(restored.indexOfCurrentDetection == 2)
        #expect(restored.currentDetectionSeries == .SOFT_FITTING_FOR_LINKBUDS_FIT)
        #expect(restored.currentDetectionSize == .L)
        // base(2) + operation(1) + index(1) + series(1) + size(1) = 6
        #expect(serialize(original).count == 6)
    }

    @Test func systemSetParamResetSettingsRoundtrip() throws {
        let original = SystemSetParamResetSettings(
            base: SystemBase(command: .SYSTEM_SET_PARAM, type: .RESET_SETTINGS),
            resetType: .FACTORY_RESET
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.resetType == .FACTORY_RESET)
        // base(2) + resetType(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemNotifyParamResetSettingsRoundtrip() throws {
        let original = SystemNotifyParamResetSettings(
            base: SystemBase(command: .SYSTEM_NTFY_PARAM, type: .RESET_SETTINGS),
            resetResult: .ERROR_CONNECTION_LEFT
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.resetResult == .ERROR_CONNECTION_LEFT)
        // base(2) + resetResult(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemNotifyParamFaceTapTestModeRoundtrip() throws {
        let original = SystemNotifyParamFaceTapTestMode(
            base: SystemBase(command: .SYSTEM_NTFY_PARAM, type: .FACE_TAP_TEST_MODE),
            key: .RIGHT_SIDE_KEY,
            action: .TRIPLE_TAP
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.key == .RIGHT_SIDE_KEY)
        #expect(restored.action == .TRIPLE_TAP)
        // base(2) + key(1) + action(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func systemExtParamSmartTalkingMode1Roundtrip() throws {
        let original = SystemExtParamSmartTalkingMode1(
            base: SystemExtBase(command: .SYSTEM_RET_EXT_PARAM, type: .SMART_TALKING_MODE_TYPE1),
            detectSensitivity: .HIGH,
            voiceFocus: .DISABLE,
            modeOffTime: .SLOW
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.detectSensitivity == .HIGH)
        #expect(restored.voiceFocus == .DISABLE)
        #expect(restored.modeOffTime == .SLOW)
        // base(2) + sensitivity(1) + voiceFocus(1) + modeOffTime(1) = 5
        #expect(serialize(original).count == 5)
    }

    @Test func systemExtParamSmartTalkingMode2Roundtrip() throws {
        let original = SystemExtParamSmartTalkingMode2(
            base: SystemExtBase(command: .SYSTEM_SET_EXT_PARAM, type: .SMART_TALKING_MODE_TYPE2),
            detectSensitivity: .LOW,
            modeOffTime: .NONE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.detectSensitivity == .LOW)
        #expect(restored.modeOffTime == .NONE)
        // base(2) + sensitivity(1) + modeOffTime(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func systemExtParamAssignableSettingsRoundtrip() throws {
        let preset1 = AssignableSettingsPreset(
            preset: .AMBIENT_SOUND_CONTROL,
            actions: MDRArray([
                AssignableSettingsAction(action: .SINGLE_TAP, function: .NO_FUNCTION),
                AssignableSettingsAction(action: .DOUBLE_TAP, function: .NO_FUNCTION),
            ])
        )
        let preset2 = AssignableSettingsPreset(
            preset: .VOLUME_CONTROL,
            actions: MDRArray([
                AssignableSettingsAction(action: .TRIPLE_TAP, function: .NO_FUNCTION),
            ])
        )
        let original = SystemExtParamAssignableSettings(
            base: SystemExtBase(command: .SYSTEM_RET_EXT_PARAM, type: .ASSIGNABLE_SETTINGS),
            presets: MDRArray([preset1, preset2])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.presets.value.count == 2)
        #expect(restored.presets.value[0].preset == .AMBIENT_SOUND_CONTROL)
        #expect(restored.presets.value[0].actions.value.count == 2)
        #expect(restored.presets.value[1].preset == .VOLUME_CONTROL)
    }

    @Test func systemExtParamWearingStatusDetectorRoundtrip() throws {
        let original = SystemExtParamWearingStatusDetector(
            base: SystemExtBase(command: .SYSTEM_RET_EXT_PARAM, type: .WEARING_STATUS_DETECTOR),
            fittingResultLeft: .POOR,
            fittingResultRight: .GOOD,
            bestEarpieceSeriesLeft: .HYBRID,
            bestEarpieceSeriesRight: .POLYURETHANE,
            bestEarpieceSizeLeft: .S,
            bestEarpieceSizeRight: .L
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.fittingResultLeft == .POOR)
        #expect(restored.fittingResultRight == .GOOD)
        #expect(restored.bestEarpieceSeriesLeft == .HYBRID)
        #expect(restored.bestEarpieceSeriesRight == .POLYURETHANE)
        #expect(restored.bestEarpieceSizeLeft == .S)
        #expect(restored.bestEarpieceSizeRight == .L)
        // base(2) + 6 fields = 8
        #expect(serialize(original).count == 8)
    }

    @Test func systemSetExtParamCallSettingsRoundtrip() throws {
        let original = SystemSetExtParamCallSettings(
            base: SystemExtBase(command: .SYSTEM_SET_EXT_PARAM, type: .CALL_SETTINGS),
            testSoundControl: .START
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.testSoundControl == .START)
        // base(2) + testSoundControl(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemNotifyExtParamCallSettingsRoundtrip() throws {
        let original = SystemNotifyExtParamCallSettings(
            base: SystemExtBase(command: .SYSTEM_NTFY_EXT_PARAM, type: .CALL_SETTINGS),
            testSoundControlAck: .ACK
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.testSoundControlAck == .ACK)
        // base(2) + ack(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func systemExtParamAssignableSettingsWithLimitRoundtrip() throws {
        let preset = AssignableSettingsPreset(
            preset: .PLAYBACK_CONTROL,
            actions: MDRArray([
                AssignableSettingsAction(action: .DOUBLE_TAP, function: .NO_FUNCTION),
            ])
        )
        let original = SystemExtParamAssignableSettingsWithLimit(
            base: SystemExtBase(command: .SYSTEM_RET_EXT_PARAM, type: .ASSIGNABLE_SETTINGS_WITH_LIMITATION),
            presets: MDRArray([preset])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.presets.value.count == 1)
        #expect(restored.presets.value[0].preset == .PLAYBACK_CONTROL)
    }
}

// MARK: - Additional Audio Tests

@Suite("T1 Additional Audio Serialization")
struct T1AdditionalAudioSerializationTests {
    @Test func audioParamUpscalingRoundtrip() throws {
        let original = AudioParamUpscaling(settingValue: .AUTO)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.settingValue == .AUTO)
        // command(1) + type(1) + settingValue(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioStatusCommonRoundtrip() throws {
        let original = AudioStatusCommon(
            type: .UPSCALING,
            status: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.status == .ENABLE)
        // command(1) + type(1) + status(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioParamConnectionWithLdacStatusRoundtrip() throws {
        let original = AudioParamConnectionWithLdacStatus(
            settingValue: .CONNECTION_QUALITY_PRIOR
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.settingValue == .CONNECTION_QUALITY_PRIOR)
        // command(1) + type(1) + settingValue(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioRetParamConnectionModeClassicAudioLeAudioRoundtrip() throws {
        let original = AudioRetParamConnectionModeClassicAudioLeAudio(
            settingValue: .CONNECTION_QUALITY_PRIOR
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.settingValue == .CONNECTION_QUALITY_PRIOR)
        // command(1) + type(1) + settingValue(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioParamVoiceContentsRoundtrip() throws {
        let original = AudioParamVoiceContents(onOffSettingValue: .ENABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.onOffSettingValue == .ENABLE)
        // command(1) + type(1) + onOff(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioParamSoundLeakageReductionRoundtrip() throws {
        let original = AudioParamSoundLeakageReduction(onOffSettingValue: .ENABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.onOffSettingValue == .ENABLE)
        // command(1) + type(1) + onOff(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioParamListeningOptionAssignCustomizableItemRoundtrip() throws {
        let original = AudioParamListeningOptionAssignCustomizableItem(
            items: PodArray<UInt8>([0x01, 0x02, 0x03, 0x04])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.items.value == [0x01, 0x02, 0x03, 0x04])
        // command(1) + type(1) + count(1) + items(4) = 7
        #expect(serialize(original).count == 7)
    }

    @Test func audioParamUpmixSeriesRoundtrip() throws {
        let original = AudioParamUpmixSeries(upmixItemId: .GAME)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.upmixItemId == .GAME)
        // command(1) + type(1) + upmixItemId(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func audioNtfyParamConnectionModeClassicAudioLeAudioRoundtrip() throws {
        let original = AudioNtfyParamConnectionModeClassicAudioLeAudio(
            settingValue: .CONNECTION_QUALITY_PRIOR,
            switchingStream: .LE_AUDIO
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.settingValue == .CONNECTION_QUALITY_PRIOR)
        #expect(restored.switchingStream == .LE_AUDIO)
        // command(1) + type(1) + settingValue(1) + switchingStream(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func audioRetCapabilityUpscalingRoundtrip() throws {
        let original = AudioRetCapabilityUpscaling(upscalingType: .DSEE_ULTIMATE)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.upscalingType == .DSEE_ULTIMATE)
        // command(1) + type(1) + upscalingType(1) = 3
        #expect(serialize(original).count == 3)
    }
}

// MARK: - Additional Alert Tests

@Suite("T1 Additional Alert Serialization")
struct T1AdditionalAlertSerializationTests {
    @Test func alertRetStatusVoiceAssistantRoundtrip() throws {
        let original = AlertRetStatusVoiceAssistant(
            voiceAssistants: PodArray<UInt8>([0x30, 0x31, 0x32])
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.voiceAssistants.value.count == 3)
        // command(1) + type(1) + count(1) + assistants(3) = 6
        #expect(serialize(original).count == 6)
    }

    @Test func alertSetStatusAppBecomesForegroundRoundtrip() throws {
        let original = AlertSetStatusAppBecomesForeground(status: .ENABLE)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.status == .ENABLE)
        // command(1) + type(1) + status(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func alertSetStatusLEAudioAlertNotificationRoundtrip() throws {
        let original = AlertSetStatusLEAudioAlertNotification(
            leAudioAlertStatus: .ENABLE,
            confirmationType: .CONFIRMED_DONT_SHOW_AGAIN
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.leAudioAlertStatus == .ENABLE)
        #expect(restored.confirmationType == .CONFIRMED_DONT_SHOW_AGAIN)
        // command(1) + type(1) + status(1) + confirmation(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func alertSetParamVibratorRoundtrip() throws {
        let original = AlertSetParamVibrator(vibrationType: .NO_PATTERN_SPECIFIED)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.vibrationType == .NO_PATTERN_SPECIFIED)
        // command(1) + type(1) + vibrationType(1) = 3
        #expect(serialize(original).count == 3)
    }

    @Test func alertSetParamFixedMessageWithLeftRightSelectionRoundtrip() throws {
        let original = AlertSetParamFixedMessageWithLeftRightSelection(
            messageType: .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_SENSOR,
            actionType: .RIGHT
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.messageType == .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_SENSOR)
        #expect(restored.actionType == .RIGHT)
        // command(1) + type(1) + messageType(1) + actionType(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func alertSetParamAppBecomesForegroundRoundtrip() throws {
        let original = AlertSetParamAppBecomesForeground(
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .POSITIVE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.messageType == .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE)
        #expect(restored.actionType == .POSITIVE)
        // command(1) + type(1) + messageType(1) + actionType(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func alertSetParamFlexibleMessageRoundtrip() throws {
        let original = AlertSetParamFlexibleMessage(
            messageType: .CAUTION_FOR_FEATURES_EXCLUSIVE_TO_MULTI_POINT,
            actionType: .POSITIVE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.messageType == .CAUTION_FOR_FEATURES_EXCLUSIVE_TO_MULTI_POINT)
        #expect(restored.actionType == .POSITIVE)
        // command(1) + type(1) + messageType(1) + actionType(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func alertNotifyParamFixedMessageRoundtrip() throws {
        let original = AlertNotifyParamFixedMessage(
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .POSITIVE_NEGATIVE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.messageType == .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE)
        #expect(restored.actionType == .POSITIVE_NEGATIVE)
        // command(1) + type(1) + messageType(1) + actionType(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func alertNotifyParamFixedMessageWithLeftRightSelectionRoundtrip() throws {
        let original = AlertNotifyParamFixedMessageWithLeftRightSelection(
            messageType: .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_BUTTON,
            defaultSelectedValue: .RIGHT
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.messageType == .CAUTION_FOR_CHANGE_VOICE_ASSISTANT_ASSIGNABLE_BUTTON)
        #expect(restored.defaultSelectedValue == .RIGHT)
        // command(1) + type(1) + messageType(1) + defaultSelected(1) = 4
        #expect(serialize(original).count == 4)
    }

    @Test func alertNotifyParamAppBecomesForegroundRoundtrip() throws {
        let original = AlertNotifyParamAppBecomesForeground(
            messageType: .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE,
            actionType: .POSITIVE_CONFIRMATION_WITH_REPLY
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.messageType == .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE)
        #expect(restored.actionType == .POSITIVE_CONFIRMATION_WITH_REPLY)
        // command(1) + type(1) + messageType(1) + actionType(1) = 4
        #expect(serialize(original).count == 4)
    }
}

// MARK: - Additional Power Tests

@Suite("T1 Additional Power Serialization")
struct T1AdditionalPowerSerializationTests {
    @Test func powerRetStatusCradleBatteryThresholdRoundtrip() throws {
        let original = PowerRetStatusCradleBatteryThreshold(
            batteryStatus: PowerBatteryThresholdStatus(
                batteryStatus: PowerBatteryStatus(batteryLevel: 75, chargingStatus: .CHARGING),
                batteryThreshold: 30
            )
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.batteryStatus.batteryStatus.batteryLevel == 75)
        #expect(restored.batteryStatus.batteryStatus.chargingStatus == .CHARGING)
        #expect(restored.batteryStatus.batteryThreshold == 30)
        // command(1) + type(1) + batteryLevel(1) + chargingStatus(1) + threshold(1) = 5
        #expect(serialize(original).count == 5)
    }

    @Test func powerParamAutoPowerOffWithWearingDetectionRoundtrip() throws {
        let original = PowerParamAutoPowerOffWithWearingDetection(
            currentPowerOffElements: .POWER_OFF_WHEN_REMOVED_FROM_EARS,
            lastSelectPowerOffElements: .POWER_OFF_IN_60_MIN
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.currentPowerOffElements == .POWER_OFF_WHEN_REMOVED_FROM_EARS)
        #expect(restored.lastSelectPowerOffElements == .POWER_OFF_IN_60_MIN)
        // command(1) + type(1) + current(1) + last(1) = 4
        #expect(serialize(original).count == 4)
    }
}

// MARK: - Additional Play Tests

@Suite("T1 Additional Play Serialization")
struct T1AdditionalPlaySerializationTests {
    @Test func playStatusPlaybackControlWithCallVolumeAdjustmentAndFunctionChangeRoundtrip() throws {
        let original = PlayStatusPlaybackControlWithCallVolumeAdjustmentAndFunctionChange(
            status: .ENABLE,
            playbackStatus: .PLAY,
            musicCallStatus: .CALL,
            playbackControlStatus: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.status == .ENABLE)
        #expect(restored.playbackStatus == .PLAY)
        #expect(restored.musicCallStatus == .CALL)
        #expect(restored.playbackControlStatus == .ENABLE)
        // command(1) + type(1) + status(1) + playback(1) + musicCall(1) + playbackControl(1) = 6
        #expect(serialize(original).count == 6)
    }

    @Test func playStatusPlaybackControlWithFunctionChangeRoundtrip() throws {
        let original = PlayStatusPlaybackControlWithFunctionChange(
            status: .ENABLE,
            playbackStatus: .PAUSE,
            playbackControlStatus: .DISABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.status == .ENABLE)
        #expect(restored.playbackStatus == .PAUSE)
        #expect(restored.playbackControlStatus == .DISABLE)
        // command(1) + type(1) + status(1) + playback(1) + playbackControl(1) = 5
        #expect(serialize(original).count == 5)
    }
}

// MARK: - Additional Connect Tests

@Suite("T1 Additional Connect Serialization")
struct T1AdditionalConnectSerializationTests {
    @Test func connectRetDeviceInfoBaseRoundtrip() throws {
        let original = ConnectRetDeviceInfoBase(
            command: .CONNECT_RET_DEVICE_INFO,
            type: .FW_VERSION
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.type == .FW_VERSION)
        // command(1) + type(1) = 2
        #expect(serialize(original).count == 2)
    }
}
