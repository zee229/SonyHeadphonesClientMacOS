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
