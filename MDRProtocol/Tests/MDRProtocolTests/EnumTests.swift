import Testing
import Foundation
@testable import MDRProtocol

// MARK: - V2 Enum Tests

@Suite("V2 Enums")
struct V2EnumTests {
    @Test func enableDisableRawValues() {
        #expect(MessageMdrV2EnableDisable.ENABLE.rawValue == 0)
        #expect(MessageMdrV2EnableDisable.DISABLE.rawValue == 1)
    }

    @Test func onOffSettingRawValues() {
        #expect(MessageMdrV2OnOffSettingValue.ON.rawValue == 0)
        #expect(MessageMdrV2OnOffSettingValue.OFF.rawValue == 1)
    }

    @Test func functionTypeTable1SpotCheck() {
        #expect(MessageMdrV2FunctionType_Table1.CONCIERGE_DATA.rawValue == 0x10)
        #expect(MessageMdrV2FunctionType_Table1.BATTERY_LEVEL_INDICATOR.rawValue == 0x20)
        #expect(MessageMdrV2FunctionType_Table1.PRESET_EQ.rawValue == 0x50)
        #expect(MessageMdrV2FunctionType_Table1.NOISE_CANCELLING_ONOFF.rawValue == 0x61)
        #expect(MessageMdrV2FunctionType_Table1.MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT.rawValue == 0x6B)
        #expect(MessageMdrV2FunctionType_Table1.PLAYBACK_CONTROLLER_WITH_CALL_VOLUME_ADJUSTMENT.rawValue == 0xA1)
        #expect(MessageMdrV2FunctionType_Table1.ASSIGNABLE_SETTING.rawValue == 0xF3)
        #expect(MessageMdrV2FunctionType_Table1.HEAD_GESTURE_ON_OFF_TRAINING.rawValue == 0xFF)
        #expect(MessageMdrV2FunctionType_Table1.GENERAL_SETTING_1.rawValue == 0xD1)
        #expect(MessageMdrV2FunctionType_Table1.AUTO_PLAY.rawValue == 0xB1)
    }

    @Test func functionTypeTable1InvalidRawValue() {
        // 0x00 is not defined in Table1
        #expect(MessageMdrV2FunctionType_Table1(rawValue: 0x00) == nil)
    }

    @Test func functionTypeTable2SpotCheck() {
        #expect(MessageMdrV2FunctionType_Table2.AUTO_STANDBY.rawValue == 0x20)
        #expect(MessageMdrV2FunctionType_Table2.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT.rawValue == 0x30)
        #expect(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_1.rawValue == 0x50)
        #expect(MessageMdrV2FunctionType_Table2.WEARING_STATUS_CHECKER.rawValue == 0xF0)
        #expect(MessageMdrV2FunctionType_Table2.LIGHTING_MODE.rawValue == 0xFC)
    }

    @Test func functionTypeTable2InvalidRawValue() {
        #expect(MessageMdrV2FunctionType_Table2(rawValue: 0x00) == nil)
        #expect(MessageMdrV2FunctionType_Table2(rawValue: 0xFF) == nil)
    }
}

// MARK: - T1 Command Tests

@Suite("T1 Command")
struct T1CommandTests {
    @Test func firstAndLastValues() {
        #expect(T1Command.CONNECT_GET_PROTOCOL_INFO.rawValue == 0x00)
        #expect(T1Command.UNKNOWN.rawValue == 0xFF)
    }

    @Test func spotCheckCommandValues() {
        #expect(T1Command.CONNECT_RET_SUPPORT_FUNCTION.rawValue == 0x07)
        #expect(T1Command.POWER_GET_STATUS.rawValue == 0x22)
        #expect(T1Command.POWER_RET_STATUS.rawValue == 0x23)
        #expect(T1Command.EQEBB_GET_PARAM.rawValue == 0x56)
        #expect(T1Command.EQEBB_SET_PARAM.rawValue == 0x58)
        #expect(T1Command.NCASM_GET_PARAM.rawValue == 0x66)
        #expect(T1Command.NCASM_SET_PARAM.rawValue == 0x68)
        #expect(T1Command.PLAY_GET_PARAM.rawValue == 0xA6)
        #expect(T1Command.PLAY_SET_PARAM.rawValue == 0xA8)
        #expect(T1Command.SYSTEM_GET_PARAM.rawValue == 0xF6)
        #expect(T1Command.SYSTEM_SET_PARAM.rawValue == 0xF8)
    }

    @Test func invalidRawValue() {
        // 0x0E is not defined
        #expect(T1Command(rawValue: 0x0E) == nil)
    }
}

// MARK: - T1 Enum Tests

@Suite("T1 Enums")
struct T1EnumTests {
    @Test func connectInquiredType() {
        #expect(ConnectInquiredType.FIXED_VALUE.rawValue == 0)
    }

    @Test func deviceInfoType() {
        #expect(DeviceInfoType.MODEL_NAME.rawValue == 1)
        #expect(DeviceInfoType.FW_VERSION.rawValue == 2)
        #expect(DeviceInfoType.SERIES_AND_COLOR_INFO.rawValue == 3)
        #expect(DeviceInfoType.INSTRUCTION_GUIDE.rawValue == 4)
    }

    @Test func modelColor() {
        #expect(ModelColor.DEFAULT.rawValue == 0)
        #expect(ModelColor.BLACK.rawValue == 1)
        #expect(ModelColor.VIOLET.rawValue == 14)
    }

    @Test func modelSeriesType() {
        #expect(ModelSeriesType.NO_SERIES.rawValue == 0)
        #expect(ModelSeriesType.EXTRA_BASS.rawValue == 0x10)
        #expect(ModelSeriesType.LINK_BUDS.rawValue == 0x60)
        #expect(ModelSeriesType.GAMING.rawValue == 0x90)
    }

    @Test func audioCodec() {
        #expect(AudioCodec.UNSETTLED.rawValue == 0x00)
        #expect(AudioCodec.SBC.rawValue == 0x01)
        #expect(AudioCodec.AAC.rawValue == 0x02)
        #expect(AudioCodec.LDAC.rawValue == 0x10)
        #expect(AudioCodec.LC3.rawValue == 0x30)
        #expect(AudioCodec.OTHER.rawValue == 0xFF)
    }

    @Test func batteryChargingStatus() {
        #expect(BatteryChargingStatus.NOT_CHARGING.rawValue == 0)
        #expect(BatteryChargingStatus.CHARGING.rawValue == 1)
        #expect(BatteryChargingStatus.UNKNOWN.rawValue == 2)
        #expect(BatteryChargingStatus.CHARGED.rawValue == 3)
    }

    @Test func eqPresetId() {
        #expect(EqPresetId.OFF.rawValue == 0x00)
        #expect(EqPresetId.ROCK.rawValue == 0x01)
        #expect(EqPresetId.CUSTOM.rawValue == 0xA0)
        #expect(EqPresetId.UNSPECIFIED.rawValue == 0xFF)
        #expect(EqPresetId.BRIGHT.rawValue == 0x10)
        #expect(EqPresetId.GAMING_EQ.rawValue == 0x20)
    }

    @Test func ncAsmInquiredType() {
        #expect(NcAsmInquiredType.NC_ON_OFF.rawValue == 0x1)
        #expect(NcAsmInquiredType.MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS.rawValue == 0x17)
        #expect(NcAsmInquiredType.MODE_NC_ASM_DUAL_NC_MODE_SWITCH_AND_ASM_SEAMLESS_NA.rawValue == 0x19)
        #expect(NcAsmInquiredType.NC_AMB_TOGGLE.rawValue == 0x30)
    }

    @Test func ncAsmMode() {
        #expect(NcAsmMode.NC.rawValue == 0)
        #expect(NcAsmMode.ASM.rawValue == 1)
    }

    @Test func playbackControl() {
        #expect(PlaybackControl.KEY_OFF.rawValue == 0x00)
        #expect(PlaybackControl.PAUSE.rawValue == 0x01)
        #expect(PlaybackControl.PLAY.rawValue == 0x07)
    }

    @Test func functionEnum() {
        #expect(Function.NO_FUNCTION.rawValue == 0x00)
        #expect(Function.NC_ASM_OFF.rawValue == 0x01)
        #expect(Function.PLAY_PAUSE.rawValue == 0x20)
        #expect(Function.VOICE_RECOGNITION.rawValue == 0x30)
        #expect(Function.MIC_MUTE.rawValue == 0x70)
    }

    @Test func presetEnum() {
        #expect(Preset.AMBIENT_SOUND_CONTROL.rawValue == 0x00)
        #expect(Preset.VOLUME_CONTROL.rawValue == 0x10)
        #expect(Preset.PLAYBACK_CONTROL.rawValue == 0x20)
        #expect(Preset.GOOGLE_ASSIST.rawValue == 0x31)
        #expect(Preset.NO_FUNCTION.rawValue == 0xFF)
    }

    @Test func alertMessageTypeSpotCheck() {
        #expect(AlertMessageType.DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE.rawValue == 0x00)
        #expect(AlertMessageType.TURN_KEY_EQ_SUCCESS.rawValue == 0x93)
    }

    @Test func powerInquiredType() {
        #expect(PowerInquiredType.BATTERY.rawValue == 0x00)
        #expect(PowerInquiredType.LEFT_RIGHT_BATTERY.rawValue == 0x01)
        #expect(PowerInquiredType.CRADLE_BATTERY.rawValue == 0x02)
        #expect(PowerInquiredType.AUTO_POWER_OFF.rawValue == 0x04)
    }

    @Test func systemInquiredType() {
        #expect(SystemInquiredType.VIBRATOR.rawValue == 0x00)
        #expect(SystemInquiredType.ASSIGNABLE_SETTINGS.rawValue == 0x03)
        #expect(SystemInquiredType.HEAD_GESTURE_TRAINING.rawValue == 0x10)
    }

    @Test func invalidEnumRawValues() {
        #expect(NcAsmMode(rawValue: 0xFF) == nil)
        #expect(AudioCodec(rawValue: 0x05) == nil)
        #expect(BatteryChargingStatus(rawValue: 0x04) == nil)
    }
}

// MARK: - T2 Command Tests

@Suite("T2 Command")
struct T2CommandTests {
    @Test func spotCheckValues() {
        #expect(T2Command.CONNECT_GET_SUPPORT_FUNCTION.rawValue == 0x06)
        #expect(T2Command.CONNECT_RET_SUPPORT_FUNCTION.rawValue == 0x07)
        #expect(T2Command.PERI_GET_STATUS.rawValue == 0x32)
        #expect(T2Command.VOICE_GUIDANCE_GET_PARAM.rawValue == 0x46)
        #expect(T2Command.SAFE_LISTENING_GET_EXTENDED_PARAM.rawValue == 0x5A)
    }
}

// MARK: - T2 Enum Tests

@Suite("T2 Enums")
struct T2EnumTests {
    @Test func peripheralInquiredType() {
        #expect(PeripheralInquiredType.PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT.rawValue == 0x00)
        #expect(PeripheralInquiredType.SOURCE_SWITCH_CONTROL.rawValue == 0x01)
    }

    @Test func voiceGuidanceInquiredType() {
        #expect(VoiceGuidanceInquiredType.MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH.rawValue == 0x00)
    }

    @Test func safeListeningInquiredType() {
        #expect(SafeListeningInquiredType.SAFE_LISTENING_HBS_1.rawValue == 0x00)
        #expect(SafeListeningInquiredType.SAFE_LISTENING_TWS_2.rawValue == 0x03)
    }

    @Test func t2ConnectInquiredType() {
        #expect(T2ConnectInquiredType.FIXED_VALUE.rawValue == 0)
    }
}
