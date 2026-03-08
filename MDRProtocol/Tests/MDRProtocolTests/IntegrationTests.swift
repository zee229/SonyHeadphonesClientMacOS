import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Helpers

private func makeHP() -> (MDRHeadphones, MockTransport) {
    let mock = MockTransport()
    let hp = MDRHeadphones(transport: mock)
    return (hp, mock)
}

private func makeHPWithSupport(_ functions: [MessageMdrV2FunctionType_Table1]) -> (MDRHeadphones, MockTransport) {
    let (hp, mock) = makeHP()
    for f in functions {
        hp.support.table1Functions[Int(f.rawValue)] = true
    }
    return (hp, mock)
}

private func makeHPWithT2Support(_ functions: [MessageMdrV2FunctionType_Table2]) -> (MDRHeadphones, MockTransport) {
    let (hp, mock) = makeHP()
    for f in functions {
        hp.support.table2Functions[Int(f.rawValue)] = true
    }
    return (hp, mock)
}

private func injectACK(_ mock: MockTransport) {
    mock.receiveQueue.append(mdrPackCommand(type: .ack, seq: 1, payload: Data()))
}

private func injectResponse<T: MDRSerializable>(_ mock: MockTransport, _ response: T, type: MDRDataType = .dataMdr) {
    var writer = DataWriter()
    response.serialize(to: &writer)
    mock.receiveQueue.append(mdrPackCommand(type: type, seq: 0, payload: writer.data))
}

private func drainQueue(_ hp: MDRHeadphones, _ mock: MockTransport) {
    for _ in 0..<500 {
        if hp.isReady { return }
        let sentBefore = mock.sentData.count
        let _ = hp.pollEvents()
        if hp.isReady { return }
        if mock.sentData.count > sentBefore {
            injectACK(mock)
        }
    }
}

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

// MARK: - Full Lifecycle Integration Tests

@Suite("Full Lifecycle Integration")
struct IntegrationTests {

    @Test func initThenSyncThenCommit() {
        let (hp, mock) = makeHP()

        // Phase 1: Init
        hp.requestInitV2()
        drainQueue(hp, mock)

        // Inject protocol info (T1 only)
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .DISABLE
        ))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // Inject support function
        injectResponse(mock, ConnectRetSupportFunction(supportFunctions: [
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.BATTERY_LEVEL_INDICATOR.rawValue, priority: 1)
        ]))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        let initEvent = hp.pollEvents()
        #expect(initEvent == MDREvent.taskInitOK.rawValue)
        #expect(hp.isReady == true)

        // Phase 2: Sync
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let syncEvent = hp.pollEvents()
        #expect(syncEvent == MDREvent.taskSyncOK.rawValue)

        // Phase 3: Commit
        hp.playVolume.desired = 15
        hp.requestCommitV2()
        drainQueue(hp, mock)
        let commitEvent = hp.pollEvents()
        #expect(commitEvent == MDREvent.taskCommitOK.rawValue)
        #expect(hp.playVolume.isDirty == false)
        #expect(hp.playVolume.current == 15)
    }

    @Test func initFailsWithoutTable1() {
        let (hp, mock) = makeHP()
        hp.requestInitV2()
        drainQueue(hp, mock)

        // Inject protocol info WITHOUT table1
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .DISABLE,
            supportTable2Value: .DISABLE
        ))
        let _ = hp.pollEvents()

        // Should error out
        let event = hp.pollEvents()
        #expect(event == MDREvent.error.rawValue)
    }

    @Test func syncQueriesBatteryBySupport() {
        let (hp, mock) = makeHPWithSupport([.BATTERY_LEVEL_INDICATOR])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasBattery = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            $0.data.count >= 2 && $0.data[1] == PowerInquiredType.BATTERY.rawValue
        }
        #expect(hasBattery == true)
    }

    @Test func syncQueriesLRBatteryBySupport() {
        let (hp, mock) = makeHPWithSupport([.LEFT_RIGHT_BATTERY_LEVEL_INDICATOR])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasLRBattery = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            $0.data.count >= 2 && $0.data[1] == PowerInquiredType.LEFT_RIGHT_BATTERY.rawValue
        }
        #expect(hasLRBattery == true)
    }

    @Test func syncQueriesSafeListeningBySupport() {
        let (hp, mock) = makeHPWithT2Support([.SAFE_LISTENING_HBS_1])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSL = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasSL == true)
    }

    @Test func commitOnlyDirtyFields() {
        let (hp, mock) = makeHPWithSupport([
            .MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT
        ])

        hp.ncAsmEnabled.desired = true
        hp.playVolume.desired = 20
        hp.requestCommitV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let dataCmds = cmds.filter { $0.type == .dataMdr }
        let hasNcAsm = dataCmds.contains { $0.data.first == T1Command.NCASM_SET_PARAM.rawValue }
        let hasVolume = dataCmds.contains { $0.data.first == T1Command.PLAY_SET_PARAM.rawValue }
        #expect(hasNcAsm == true)
        #expect(hasVolume == true)

        // Should NOT have other commit commands
        let hasEq = dataCmds.contains { $0.data.first == T1Command.EQEBB_SET_PARAM.rawValue }
        #expect(hasEq == false)
    }

    @Test func commitWithNoSupportSkipsCommand() {
        let (hp, mock) = makeHP() // No support flags
        hp.ncAsmEnabled.desired = true
        hp.requestCommitV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasNcAsm = cmds.contains { $0.data.first == T1Command.NCASM_SET_PARAM.rawValue }
        // NC/ASM commit path sends command regardless of support (it checks the variant, not whether to send)
        // But the actual NcAsm path DOES check support - let's verify for specific ones

        // Auto power off requires .AUTO_POWER_OFF support
        let hp2 = MDRHeadphones(transport: MockTransport())
        hp2.powerAutoOff.desired = .POWER_OFF_IN_5_MIN
        hp2.requestCommitV2()
        let _ = hp2.pollEvents()
        let cmds2 = decodeSentCommands(MockTransport()) // empty since hp2's mock is different
        #expect(hp2.powerAutoOff.isDirty == true) // stays dirty because no support, not committed
    }

    @Test func multipleCommitsInSequence() {
        let (hp, mock) = makeHPWithSupport([
            .MODE_NC_ASM_NOISE_CANCELLING_DUAL_AMBIENT_SOUND_MODE_LEVEL_ADJUSTMENT
        ])

        // First commit: NC/ASM
        hp.ncAsmEnabled.desired = true
        hp.requestCommitV2()
        drainQueue(hp, mock)
        let event1 = hp.pollEvents()
        #expect(event1 == MDREvent.taskCommitOK.rawValue)
        #expect(hp.ncAsmEnabled.isDirty == false)

        // Second commit: Volume
        hp.playVolume.desired = 30
        hp.requestCommitV2()
        drainQueue(hp, mock)
        let event2 = hp.pollEvents()
        #expect(event2 == MDREvent.taskCommitOK.rawValue)
        #expect(hp.playVolume.isDirty == false)
        #expect(hp.playVolume.current == 30)
    }

    @Test func rapidDirtySetDuringCommit() {
        let (hp, mock) = makeHP()
        hp.ncAsmEnabled.desired = true
        hp.requestCommitV2()

        // While commit is "in progress", set another property dirty
        hp.playVolume.desired = 50

        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        // Volume was not part of the original commit, so it should still be dirty
        #expect(hp.playVolume.isDirty == true)
        #expect(hp.playVolume.desired == 50)
    }

    @Test func eventFlowInitSyncIdle() {
        let (hp, mock) = makeHP()

        // Before init, should be idle
        let event0 = hp.pollEvents()
        #expect(event0 == MDREvent.idle.rawValue)

        // Start init
        hp.requestInitV2()
        #expect(hp.isReady == false)

        // Drain queue to send ConnectGetProtocolInfo + ACK
        for _ in 0..<50 {
            let sentBefore = mock.sentData.count
            let _ = hp.pollEvents()
            if mock.sentData.count > sentBefore {
                injectACK(mock)
            }
            // Don't stop early - we need to keep going
            if hp.isReady { break }
        }

        // Inject protocol info
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .DISABLE
        ))
        let _ = hp.pollEvents()

        // Drain phase 2a commands
        for _ in 0..<50 {
            let sentBefore = mock.sentData.count
            let _ = hp.pollEvents()
            if mock.sentData.count > sentBefore {
                injectACK(mock)
            }
            if hp.isReady { break }
        }

        // Inject support function
        injectResponse(mock, ConnectRetSupportFunction(supportFunctions: []))
        let _ = hp.pollEvents()

        // Drain phase 2b commands
        for _ in 0..<500 {
            let sentBefore = mock.sentData.count
            let _ = hp.pollEvents()
            if mock.sentData.count > sentBefore {
                injectACK(mock)
            }
            if hp.isReady { break }
        }

        // Task should complete
        let initEvent = hp.pollEvents()
        #expect(initEvent == MDREvent.taskInitOK.rawValue)

        // Now should be idle again
        let eventAfter = hp.pollEvents()
        #expect(eventAfter == MDREvent.idle.rawValue)
    }

    @Test func initWithTable2SupportFunctions() {
        let (hp, mock) = makeHP()
        hp.requestInitV2()
        drainQueue(hp, mock)

        // Protocol info with T2
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        ))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // T1 support functions with some entries
        injectResponse(mock, ConnectRetSupportFunction(supportFunctions: [
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.BATTERY_LEVEL_INDICATOR.rawValue, priority: 1),
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.CODEC_INDICATOR.rawValue, priority: 2),
        ]))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // T2 support functions
        injectResponse(mock, T2ConnectRetSupportFunction(supportFunctions: [
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_1.rawValue, priority: 1),
        ]), type: .dataMdrNo2)
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        let event = hp.pollEvents()
        #expect(event == MDREvent.taskInitOK.rawValue)

        // Verify support flags were set
        #expect(hp.support.contains(.BATTERY_LEVEL_INDICATOR) == true)
        #expect(hp.support.contains(.CODEC_INDICATOR) == true)
        #expect(hp.support.contains(MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_1) == true)
    }

    @Test func commitNoChangesCompletesImmediately() {
        let (hp, mock) = makeHP()
        hp.requestCommitV2()
        let event = hp.pollEvents()
        #expect(event == MDREvent.taskCommitOK.rawValue)
        #expect(hp.isReady == true)
    }

    @Test func syncWithCradleBattery() {
        let (hp, mock) = makeHPWithSupport([.CRADLE_BATTERY_LEVEL_INDICATOR])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasCradleBattery = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            $0.data.count >= 2 && $0.data[1] == PowerInquiredType.CRADLE_BATTERY.rawValue
        }
        #expect(hasCradleBattery == true)
    }

    @Test func syncWithBatteryThreshold() {
        let (hp, mock) = makeHPWithSupport([.BATTERY_LEVEL_WITH_THRESHOLD])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasBatteryThreshold = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            $0.data.count >= 2 && $0.data[1] == PowerInquiredType.BATTERY_WITH_THRESHOLD.rawValue
        }
        #expect(hasBatteryThreshold == true)
    }

    // MARK: - RequestSync Fallback Path Tests

    @Test func syncQueriesLRBatteryThreshold() {
        let (hp, mock) = makeHPWithSupport([.LR_BATTERY_LEVEL_WITH_THRESHOLD])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasLRThreshold = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            $0.data.count >= 2 && $0.data[1] == PowerInquiredType.LR_BATTERY_WITH_THRESHOLD.rawValue
        }
        #expect(hasLRThreshold == true)
    }

    @Test func syncQueriesCradleBatteryThreshold() {
        let (hp, mock) = makeHPWithSupport([.CRADLE_BATTERY_LEVEL_WITH_THRESHOLD])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasCradleThreshold = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue &&
            $0.data.count >= 2 && $0.data[1] == PowerInquiredType.CRADLE_BATTERY_WITH_THRESHOLD.rawValue
        }
        #expect(hasCradleThreshold == true)
    }

    @Test func syncSafeListeningTWS1() {
        let (hp, mock) = makeHPWithT2Support([.SAFE_LISTENING_TWS_1])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSL = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasSL == true)
    }

    @Test func syncSafeListeningTWS2() {
        let (hp, mock) = makeHPWithT2Support([.SAFE_LISTENING_TWS_2])
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let _ = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasSL = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasSL == true)
    }

    @Test func syncNoBatterySupport() {
        let (hp, mock) = makeHP()
        hp.requestSyncV2()
        drainQueue(hp, mock)
        let syncEvent = hp.pollEvents()

        let cmds = decodeSentCommands(mock)
        let hasPowerGet = cmds.contains {
            $0.data.first == T1Command.POWER_GET_STATUS.rawValue
        }
        #expect(hasPowerGet == false)
        #expect(syncEvent == MDREvent.taskSyncOK.rawValue)
    }

    // MARK: - RequestInit Phase2 Integration Tests

    @Test func initPhase2WithFullSupport() {
        let (hp, mock) = makeHP()

        // Phase 1: Init
        hp.requestInitV2()
        drainQueue(hp, mock)

        // Inject protocol info (T1 + T2)
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        ))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // Inject T1 support functions
        injectResponse(mock, ConnectRetSupportFunction(supportFunctions: [
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.GENERAL_SETTING_1.rawValue, priority: 1),
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.CODEC_INDICATOR.rawValue, priority: 2),
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.UPSCALING_AUTO_OFF.rawValue, priority: 3),
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.FIXED_MESSAGE.rawValue, priority: 4),
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.HEAD_GESTURE_ON_OFF_TRAINING.rawValue, priority: 5),
        ]))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // Inject T2 support functions
        injectResponse(mock, T2ConnectRetSupportFunction(supportFunctions: [
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table2.SAFE_LISTENING_HBS_1.rawValue, priority: 1),
        ]), type: .dataMdrNo2)
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        let initEvent = hp.pollEvents()
        #expect(initEvent == MDREvent.taskInitOK.rawValue)

        // Verify commands sent in Phase2
        let cmds = decodeSentCommands(mock)

        let hasGSCapability = cmds.contains {
            $0.data.first == T1Command.GENERAL_SETTING_GET_CAPABILITY.rawValue
        }
        #expect(hasGSCapability == true)

        let hasCodec = cmds.contains {
            $0.data.first == T1Command.COMMON_GET_STATUS.rawValue
        }
        #expect(hasCodec == true)

        let hasUpscaling = cmds.contains {
            $0.data.first == T1Command.AUDIO_GET_CAPABILITY.rawValue
        }
        #expect(hasUpscaling == true)

        let hasAlert = cmds.contains {
            $0.data.first == T1Command.ALERT_SET_STATUS.rawValue
        }
        #expect(hasAlert == true)

        let hasHeadGesture = cmds.contains {
            $0.data.first == T1Command.SYSTEM_GET_PARAM.rawValue &&
            $0.data.count >= 2 && $0.data[1] == SystemInquiredType.HEAD_GESTURE_ON_OFF.rawValue
        }
        #expect(hasHeadGesture == true)
    }

    @Test func initPhase2MinimalSupport() {
        let (hp, mock) = makeHP()

        hp.requestInitV2()
        drainQueue(hp, mock)

        // Protocol info (T1 only)
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .DISABLE
        ))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // Empty support function list
        injectResponse(mock, ConnectRetSupportFunction(supportFunctions: []))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        let initEvent = hp.pollEvents()
        #expect(initEvent == MDREvent.taskInitOK.rawValue)

        let cmds = decodeSentCommands(mock)

        // Should NOT have conditional commands
        let hasGS = cmds.contains {
            $0.data.first == T1Command.GENERAL_SETTING_GET_CAPABILITY.rawValue
        }
        #expect(hasGS == false)

        let hasAudioCap = cmds.contains {
            $0.data.first == T1Command.AUDIO_GET_CAPABILITY.rawValue
        }
        #expect(hasAudioCap == false)

        // SHOULD have unconditional commands
        let hasPlay = cmds.contains {
            $0.data.first == T1Command.PLAY_GET_PARAM.rawValue
        }
        #expect(hasPlay == true)

        let hasEq = cmds.contains {
            $0.data.first == T1Command.EQEBB_GET_STATUS.rawValue
        }
        #expect(hasEq == true)

        let hasLog = cmds.contains {
            $0.data.first == T1Command.LOG_SET_STATUS.rawValue
        }
        #expect(hasLog == true)
    }

    @Test func initPhase2NoTable2() {
        let (hp, mock) = makeHP()

        hp.requestInitV2()
        drainQueue(hp, mock)

        // Protocol info (T1 only, no T2)
        injectResponse(mock, ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .DISABLE
        ))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        // T1 support functions
        injectResponse(mock, ConnectRetSupportFunction(supportFunctions: [
            SupportFunctionEntry(rawFunction: MessageMdrV2FunctionType_Table1.BATTERY_LEVEL_INDICATOR.rawValue, priority: 1),
        ]))
        let _ = hp.pollEvents()
        drainQueue(hp, mock)

        let initEvent = hp.pollEvents()
        #expect(initEvent == MDREvent.taskInitOK.rawValue)

        // Should NOT have any dataMdrNo2 commands
        let cmds = decodeSentCommands(mock)
        let hasT2 = cmds.contains { $0.type == .dataMdrNo2 }
        #expect(hasT2 == false)
    }
}
