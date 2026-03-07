import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Property Desired/Current Regression Tests

@Suite("Property Desired/Current Regression")
struct PropertyRegressionTests {

    @Test func desiredSurvivesBeforeCommit() {
        var p = MDRProperty<Int>(0)
        p.desired = 42
        #expect(p.isDirty == true)
        #expect(p.desired == 42)
        #expect(p.current == 0)
    }

    @Test func commitMakesClean() {
        var p = MDRProperty<Int>(0)
        p.desired = 42
        p.commit()
        #expect(p.isDirty == false)
        #expect(p.desired == 42)
        #expect(p.current == 42)
    }

    @Test func overwriteSetsBoth() {
        var p = MDRProperty<Int>(0)
        p.desired = 42
        p.overwrite(99)
        #expect(p.desired == 99)
        #expect(p.current == 99)
        #expect(p.isDirty == false)
    }

    @Test func desiredNotOverwrittenByCurrentUpdate() {
        var p = MDRProperty<Bool>(false)
        p.desired = true
        #expect(p.isDirty == true)

        // Reading .current gives the old value (not the user's intent)
        #expect(p.current == false)
        // Reading .desired gives the user's intent
        #expect(p.desired == true)

        // Overwrite (as handler would) clears the user's intent
        p.overwrite(false)
        #expect(p.desired == false)
        #expect(p.isDirty == false)
    }

    @Test func dirtyCheckCoversAllWritableProperties() {
        func testProperty(_ name: String, _ setter: (MDRHeadphones) -> Void) {
            let hp = MDRHeadphones(transport: MockTransport())
            #expect(hp.isDirty == false)
            setter(hp)
            #expect(hp.isDirty == true, "Expected isDirty after setting \(name)")
        }

        testProperty("shutdown") { $0.shutdown.desired = true }
        testProperty("ncAsmEnabled") { $0.ncAsmEnabled.desired = true }
        testProperty("ncAsmFocusOnVoice") { $0.ncAsmFocusOnVoice.desired = true }
        testProperty("ncAsmAmbientLevel") { $0.ncAsmAmbientLevel.desired = 10 }
        testProperty("ncAsmButtonFunction") { $0.ncAsmButtonFunction.desired = .NC_ASM }
        testProperty("ncAsmMode") { $0.ncAsmMode.desired = .ASM }
        testProperty("ncAsmAutoAsmEnabled") { $0.ncAsmAutoAsmEnabled.desired = true }
        testProperty("ncAsmNoiseAdaptiveSensitivity") { $0.ncAsmNoiseAdaptiveSensitivity.desired = .HIGH }
        testProperty("powerAutoOff") { $0.powerAutoOff.desired = .POWER_OFF_IN_5_MIN }
        testProperty("powerAutoOffWearingDetection") { $0.powerAutoOffWearingDetection.desired = .POWER_OFF_IN_5_MIN }
        testProperty("playVolume") { $0.playVolume.desired = 10 }
        testProperty("playControl") { $0.playControl.desired = .PLAY }
        testProperty("gsParamBool1") { $0.gsParamBool1.desired = true }
        testProperty("gsParamBool2") { $0.gsParamBool2.desired = true }
        testProperty("gsParamBool3") { $0.gsParamBool3.desired = true }
        testProperty("gsParamBool4") { $0.gsParamBool4.desired = true }
        testProperty("upscalingEnabled") { $0.upscalingEnabled.desired = true }
        testProperty("audioPriorityMode") { $0.audioPriorityMode.desired = .CONNECTION_QUALITY_PRIOR }
        testProperty("bgmModeEnabled") { $0.bgmModeEnabled.desired = true }
        testProperty("bgmModeRoomSize") { $0.bgmModeRoomSize.desired = .LARGE }
        testProperty("upmixCinemaEnabled") { $0.upmixCinemaEnabled.desired = true }
        testProperty("autoPauseEnabled") { $0.autoPauseEnabled.desired = true }
        testProperty("touchFunctionLeft") { $0.touchFunctionLeft.desired = .VOLUME_CONTROL }
        testProperty("touchFunctionRight") { $0.touchFunctionRight.desired = .VOLUME_CONTROL }
        testProperty("speakToChatEnabled") { $0.speakToChatEnabled.desired = true }
        testProperty("speakToChatDetectSensitivity") { $0.speakToChatDetectSensitivity.desired = .HIGH }
        testProperty("speakToModeOutTime") { $0.speakToModeOutTime.desired = .SLOW }
        testProperty("headGestureEnabled") { $0.headGestureEnabled.desired = true }
        testProperty("eqAvailable") { $0.eqAvailable.desired = true }
        testProperty("eqPresetId") { $0.eqPresetId.desired = .BRIGHT }
        testProperty("eqClearBass") { $0.eqClearBass.desired = 5 }
        testProperty("eqConfig") { $0.eqConfig.desired = [1] }
        testProperty("voiceGuidanceEnabled") { $0.voiceGuidanceEnabled.desired = true }
        testProperty("voiceGuidanceVolume") { $0.voiceGuidanceVolume.desired = 2 }
        testProperty("pairingMode") { $0.pairingMode.desired = true }
        testProperty("multipointDeviceMac") { $0.multipointDeviceMac.desired = "X" }
        testProperty("pairedDeviceDisconnectMac") { $0.pairedDeviceDisconnectMac.desired = "X" }
        testProperty("pairedDeviceConnectMac") { $0.pairedDeviceConnectMac.desired = "X" }
        testProperty("pairedDeviceUnpairMac") { $0.pairedDeviceUnpairMac.desired = "X" }
        testProperty("safeListeningPreviewMode") { $0.safeListeningPreviewMode.desired = true }
    }

    @Test func isDirtyTrueWhenDirtyFalseAfterCommit() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.ncAsmEnabled.desired = true
        #expect(hp.isDirty == true)
        hp.ncAsmEnabled.commit()
        #expect(hp.isDirty == false)
    }

    @Test func commitClearsDesiredForPropertyButPreservesValue() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.playVolume.desired = 25
        #expect(hp.playVolume.desired == 25)
        #expect(hp.playVolume.current == 0)
        hp.playVolume.commit()
        #expect(hp.playVolume.desired == 25)
        #expect(hp.playVolume.current == 25)
        #expect(hp.playVolume.isDirty == false)
    }

    @Test func handlerOverwriteResetsDirty() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.ncAsmEnabled.desired = true
        #expect(hp.ncAsmEnabled.isDirty == true)

        // Simulate handler overwrite (what happens when device sends back data)
        hp.ncAsmEnabled.overwrite(false)
        #expect(hp.ncAsmEnabled.isDirty == false)
        #expect(hp.ncAsmEnabled.desired == false)
        #expect(hp.ncAsmEnabled.current == false)
    }

    @Test func desiredSurvivesMultiplePollCycles() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.playVolume.desired = 50

        // Simulate multiple poll cycles (60Hz loop)
        for _ in 0..<60 {
            let _ = hp.pollEvents()
        }

        // Desired should survive - not overwritten by polling
        #expect(hp.playVolume.desired == 50)
        #expect(hp.playVolume.isDirty == true)
    }
}
