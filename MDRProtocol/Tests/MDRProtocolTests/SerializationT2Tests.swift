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

    // MARK: Sub-struct roundtrips

    @Test func safeListeningData1Roundtrip() throws {
        let inner = SafeListeningData(
            targetType: .TWS_L,
            timestamp: Int32BE(99999),
            rtcRC: Int16BE(200),
            viewTime: 45,
            soundPressure: Int32BE(8000)
        )
        let original = SafeListeningData1(data: inner)
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 12)
        var reader = DataReader(writer.data)
        let restored = try SafeListeningData1.read(from: &reader)
        #expect(restored == original)
    }

    @Test func safeListeningData2Roundtrip() throws {
        let inner = SafeListeningData(
            targetType: .TWS_R,
            timestamp: Int32BE(55555),
            rtcRC: Int16BE(300),
            viewTime: 60,
            soundPressure: Int32BE(3000)
        )
        let original = SafeListeningData2(data: inner, ambientTime: 42)
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 13)
        var reader = DataReader(writer.data)
        let restored = try SafeListeningData2.read(from: &reader)
        #expect(restored == original)
        #expect(restored.ambientTime == 42)
    }

    @Test func safeListeningStatusRoundtrip() throws {
        let original = SafeListeningStatus(
            timestamp: Int32BE(123456),
            rtcRC: Int16BE(500)
        )
        var writer = DataWriter()
        original.write(to: &writer)
        #expect(writer.data.count == 6)
        var reader = DataReader(writer.data)
        let restored = try SafeListeningStatus.read(from: &reader)
        #expect(restored == original)
    }

    // MARK: RetStatus roundtrips

    @Test func retStatusHbs1Roundtrip() throws {
        let data = SafeListeningData(targetType: .HBS, timestamp: Int32BE(1000), rtcRC: Int16BE(10), viewTime: 5, soundPressure: Int32BE(500))
        let original = SafeListeningRetStatusHbs1(
            logDataStatus: .SENDING,
            currentData: SafeListeningData1(data: data)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.logDataStatus == .SENDING)
        // command(1) + type(1) + logDataStatus(1) + data(12) = 15
        #expect(serialize(original).count == 15)
    }

    @Test func retStatusHbs2Roundtrip() throws {
        let data = SafeListeningData(targetType: .HBS, timestamp: Int32BE(2000), rtcRC: Int16BE(20), viewTime: 10, soundPressure: Int32BE(1500))
        let original = SafeListeningRetStatusHbs2(
            logDataStatus: .COMPLETED,
            currentData: SafeListeningData2(data: data, ambientTime: 7)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + logDataStatus(1) + data(13) = 16
        #expect(serialize(original).count == 16)
    }

    @Test func retStatusTws1Roundtrip() throws {
        let dataL = SafeListeningData(targetType: .TWS_L, timestamp: Int32BE(3000), rtcRC: Int16BE(30), viewTime: 15, soundPressure: Int32BE(2000))
        let dataR = SafeListeningData(targetType: .TWS_R, timestamp: Int32BE(3001), rtcRC: Int16BE(31), viewTime: 16, soundPressure: Int32BE(2001))
        let original = SafeListeningRetStatusTws1(
            logDataStatusLeft: .SENDING,
            logDataStatusRight: .NOT_SENDING,
            currentDataLeft: SafeListeningData1(data: dataL),
            currentDataRight: SafeListeningData1(data: dataR)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + statusL(1) + statusR(1) + dataL(12) + dataR(12) = 28
        #expect(serialize(original).count == 28)
    }

    @Test func retStatusTws2Roundtrip() throws {
        let dataL = SafeListeningData(targetType: .TWS_L, timestamp: Int32BE(4000), rtcRC: Int16BE(40), viewTime: 20, soundPressure: Int32BE(3000))
        let dataR = SafeListeningData(targetType: .TWS_R, timestamp: Int32BE(4001), rtcRC: Int16BE(41), viewTime: 21, soundPressure: Int32BE(3001))
        let original = SafeListeningRetStatusTws2(
            logDataStatusLeft: .COMPLETED,
            logDataStatusRight: .ERROR,
            currentDataLeft: SafeListeningData2(data: dataL, ambientTime: 11),
            currentDataRight: SafeListeningData2(data: dataR, ambientTime: 12)
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + statusL(1) + statusR(1) + dataL(13) + dataR(13) = 30
        #expect(serialize(original).count == 30)
    }

    // MARK: SetStatus roundtrips

    @Test func setStatusHbsRoundtrip() throws {
        let original = SafeListeningSetStatusHbs(
            logDataStatus: .SENDING,
            status: SafeListeningStatus(timestamp: Int32BE(77777), rtcRC: Int16BE(88))
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + logDataStatus(1) + status(6) = 9
        #expect(serialize(original).count == 9)
    }

    @Test func setStatusTwsRoundtrip() throws {
        let original = SafeListeningSetStatusTws(
            logDataStatusLeft: .SENDING,
            logDataStatusRight: .COMPLETED,
            statusLeft: SafeListeningStatus(timestamp: Int32BE(11111), rtcRC: Int16BE(22)),
            statusRight: SafeListeningStatus(timestamp: Int32BE(33333), rtcRC: Int16BE(44))
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + statusL(1) + statusR(1) + left(6) + right(6) = 16
        #expect(serialize(original).count == 16)
    }

    // MARK: NotifyStatus roundtrips

    @Test func notifyStatusHbs1Roundtrip() throws {
        let d1 = SafeListeningData1(data: SafeListeningData(targetType: .HBS, timestamp: Int32BE(100), rtcRC: Int16BE(1), viewTime: 1, soundPressure: Int32BE(10)))
        let d2 = SafeListeningData1(data: SafeListeningData(targetType: .HBS, timestamp: Int32BE(200), rtcRC: Int16BE(2), viewTime: 2, soundPressure: Int32BE(20)))
        let original = SafeListeningNotifyStatusHbs1(logDataStatus: .SENDING, data: [d1, d2])
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.data.count == 2)
        // command(1) + type(1) + logDataStatus(1) + count(1) + 2*12 = 28
        #expect(serialize(original).count == 28)
    }

    @Test func notifyStatusHbs2Roundtrip() throws {
        let d1 = SafeListeningData2(data: SafeListeningData(targetType: .HBS, timestamp: Int32BE(100), rtcRC: Int16BE(1), viewTime: 1, soundPressure: Int32BE(10)), ambientTime: 5)
        let original = SafeListeningNotifyStatusHbs2(logDataStatus: .COMPLETED, data: [d1])
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.data.count == 1)
        // command(1) + type(1) + logDataStatus(1) + count(1) + 1*13 = 17
        #expect(serialize(original).count == 17)
    }

    @Test func notifyStatusTws1Roundtrip() throws {
        let d1 = SafeListeningData1(data: SafeListeningData(targetType: .TWS_L, timestamp: Int32BE(300), rtcRC: Int16BE(3), viewTime: 3, soundPressure: Int32BE(30)))
        let original = SafeListeningNotifyStatusTws1(
            logDataStatusLeft: .SENDING,
            logDataStatusRight: .NOT_SENDING,
            data: [d1]
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        // command(1) + type(1) + statusL(1) + statusR(1) + count(1) + 1*12 = 17
        #expect(serialize(original).count == 17)
    }

    @Test func notifyStatusTws2Roundtrip() throws {
        let d1 = SafeListeningData2(data: SafeListeningData(targetType: .TWS_L, timestamp: Int32BE(400), rtcRC: Int16BE(4), viewTime: 4, soundPressure: Int32BE(40)), ambientTime: 8)
        let d2 = SafeListeningData2(data: SafeListeningData(targetType: .TWS_R, timestamp: Int32BE(401), rtcRC: Int16BE(5), viewTime: 5, soundPressure: Int32BE(41)), ambientTime: 9)
        let original = SafeListeningNotifyStatusTws2(
            logDataStatusLeft: .ERROR,
            logDataStatusRight: .DISCONNECTED,
            data: [d1, d2]
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(restored.data.count == 2)
        // command(1) + type(1) + statusL(1) + statusR(1) + count(1) + 2*13 = 31
        #expect(serialize(original).count == 31)
    }

    // MARK: NotifyParam roundtrips

    @Test func notifyParamSLRoundtrip() throws {
        let original = SafeListeningNotifyParamSL(
            safeListeningMode: .DISABLE,
            previewMode: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }

    @Test func notifyParamSVCRoundtrip() throws {
        let original = SafeListeningNotifyParamSVC(
            volumeLimitationMode: .DISABLE,
            safeVolumeControlMode: .ENABLE
        )
        let restored = try roundtrip(original)
        #expect(restored == original)
        #expect(serialize(original).count == 4)
    }
}
