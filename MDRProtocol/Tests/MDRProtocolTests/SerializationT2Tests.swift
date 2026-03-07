import Testing
import Foundation
@testable import MDRProtocol

// MARK: - T2 Connect Tests

@Suite("T2 Connect Serialization")
struct T2ConnectSerializationTests {
    @Test func t2ConnectGetSupportFunctionRoundtrip() throws {
        let original = T2ConnectGetSupportFunction()
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 2)
    }

    @Test func t2ConnectRetSupportFunctionRoundtrip() throws {
        let entries = [
            SupportFunctionEntry(rawFunction: 0x20, priority: 1),
            SupportFunctionEntry(rawFunction: 0x30, priority: 2),
            SupportFunctionEntry(rawFunction: 0x50, priority: 3),
        ]
        let original = T2ConnectRetSupportFunction(supportFunctions: entries)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.supportFunctions.count == 3)
    }

    @Test func t2ConnectRetSupportFunctionEmpty() throws {
        let original = T2ConnectRetSupportFunction(supportFunctions: [])
        let restored = try roundtrip(original)
        #expect(restored.supportFunctions.isEmpty)
    }
}

// MARK: - T2 Peripheral Tests

@Suite("T2 Peripheral Serialization")
struct T2PeripheralSerializationTests {
    @Test func peripheralGetStatusRoundtrip() throws {
        let original = PeripheralGetStatus(type: .PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func peripheralGetParamRoundtrip() throws {
        let original = PeripheralGetParam(type: .SOURCE_SWITCH_CONTROL)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func peripheralStatusPairingDeviceManagementRoundtrip() throws {
        let original = PeripheralStatusPairingDeviceManagementCommon(
            btMode: .NORMAL_MODE,
            enableDisableStatus: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }

    @Test func peripheralParamSourceSwitchControlRoundtrip() throws {
        let original = PeripheralParamSourceSwitchControl(sourceKeeping: .ON)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.sourceKeeping == .ON)
    }

    @Test func peripheralParamMusicHandOverSettingRoundtrip() throws {
        let original = PeripheralParamMusicHandOverSetting(isOn: .OFF)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func peripheralDeviceInfoRoundtrip() throws {
        let mac = Data("AA:BB:CC:DD:EE:FF".utf8)
        let info = PeripheralDeviceInfo(
            btDeviceAddress: mac,
            connectedStatus: 1,
            btFriendlyName: PrefixedString("My Phone")
        )
        var writer = DataWriter()
        info.write(to: &writer)
        var reader = DataReader(writer.data)
        let restored = try PeripheralDeviceInfo.read(from: &reader)
        #expect(restored == info)
        #expect(restored.btFriendlyName.value == "My Phone")
    }

    @Test func peripheralSetExtendedParamSourceSwitchControlRoundtrip() throws {
        let mac = Data("11:22:33:44:55:66".utf8)
        let original = PeripheralSetExtendedParamSourceSwitchControl(targetBdAddress: mac)
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + mac(17) = 19
        #expect(serialize(original).count == 19)
    }
}

// MARK: - T2 VoiceGuidance Tests

@Suite("T2 VoiceGuidance Serialization")
struct T2VoiceGuidanceSerializationTests {
    @Test func voiceGuidanceGetParamRoundtrip() throws {
        let original = VoiceGuidanceGetParam(type: .VOLUME)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func voiceGuidanceParamSettingMtkRoundtrip() throws {
        let original = VoiceGuidanceParamSettingMtk(settingValue: .ON)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 3)
    }

    @Test func voiceGuidanceParamSettingSupportLangSwitchRoundtrip() throws {
        let original = VoiceGuidanceParamSettingSupportLangSwitch(
            settingValue: .ON,
            languageValue: .JAPANESE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.languageValue == .JAPANESE)
    }

    @Test func voiceGuidanceParamVolumeRoundtrip() throws {
        let original = VoiceGuidanceParamVolume(volumeValue: -2)
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.volumeValue == -2)
    }

    @Test func voiceGuidanceParamVolumePositive() throws {
        let original = VoiceGuidanceParamVolume(volumeValue: 2)
        let restored = try roundtrip(original)
        #expect(restored.volumeValue == 2)
    }

    @Test func voiceGuidanceSetParamVolumeRoundtrip() throws {
        let original = VoiceGuidanceSetParamVolume(
            volumeValue: 1,
            feedbackSound: .ON
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }

    @Test func voiceGuidanceParamSettingOnOffRoundtrip() throws {
        let original = VoiceGuidanceParamSettingOnOff(settingValue: .OFF)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }
}

// MARK: - T2 SafeListening Tests

@Suite("T2 SafeListening Serialization")
struct T2SafeListeningSerializationTests {
    @Test func safeListeningGetCapabilityRoundtrip() throws {
        let original = SafeListeningGetCapability(type: .SAFE_LISTENING_HBS_1)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func safeListeningRetCapabilityRoundtrip() throws {
        let original = SafeListeningRetCapability(
            inquiredType: .SAFE_LISTENING_HBS_1,
            roundBase: 5,
            timestampBase: Int32BE(1000),
            minimumInterval: 10,
            logCapacity: 50
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.roundBase == 5)
        #expect(restored.timestampBase.value == 1000)
        // command(1) + type(1) + roundBase(1) + timestamp(4) + minInterval(1) + logCapacity(1) = 9
        #expect(serialize(original).count == 9)
    }

    @Test func safeListeningGetStatusRoundtrip() throws {
        let original = SafeListeningGetStatus(inquiredType: .SAFE_LISTENING_TWS_2)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func safeListeningGetParamRoundtrip() throws {
        let original = SafeListeningGetParam(inquiredType: .SAFE_LISTENING_HBS_1)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func safeListeningRetParamRoundtrip() throws {
        let original = SafeListeningRetParam(
            inquiredType: .SAFE_LISTENING_HBS_1,
            availability: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.availability == .ENABLE)
    }

    @Test func safeListeningSetParamSLRoundtrip() throws {
        let original = SafeListeningSetParamSL(
            safeListeningMode: .ENABLE,
            previewMode: .DISABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }

    @Test func safeListeningSetParamSVCRoundtrip() throws {
        let original = SafeListeningSetParamSVC(
            volumeLimitationMode: .ENABLE,
            safeVolumeControlMode: .DISABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func safeListeningGetExtendedParamRoundtrip() throws {
        let original = SafeListeningGetExtendedParam(type: .SAFE_LISTENING_HBS_1)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func safeListeningRetExtendedParamRoundtrip() throws {
        let original = SafeListeningRetExtendedParam(
            inquiredType: .SAFE_LISTENING_HBS_1,
            levelPerPeriod: 75,
            errorCause: .NOT_PLAYING
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.levelPerPeriod == 75)
    }

    @Test func safeListeningDataSubStructRoundtrip() throws {
        let data = SafeListeningData(
            targetType: .HBS,
            timestamp: Int32BE(12345),
            rtcRC: Int16BE(100),
            viewTime: 30,
            soundPressure: Int32BE(5000)
        )
        var writer = DataWriter()
        data.write(to: &writer)
        #expect(writer.data.count == 12) // 1+4+2+1+4
        var reader = DataReader(writer.data)
        let restored = try SafeListeningData.read(from: &reader)
        #expect(restored == data)
    }

    @Test func safeListeningSetStatusSVCRoundtrip() throws {
        let original = SafeListeningSetStatusSVC(whoStandardLevel: .SENSITIVE)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }

    @Test func safeListeningNotifyStatusSVCRoundtrip() throws {
        let original = SafeListeningNotifyStatusSVC(whoStandardLevel: .NORMAL)
        let restored = try roundtrip(original)
        #expect(restored == original)
    }
}
