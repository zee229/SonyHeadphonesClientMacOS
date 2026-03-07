import Testing
import Foundation
@testable import MDRProtocol

// MARK: - Helpers

private func makeHP() -> (MDRHeadphones, MockTransport) {
    let mock = MockTransport()
    let hp = MDRHeadphones(transport: mock)
    return (hp, mock)
}

private func injectACK(_ mock: MockTransport) {
    mock.receiveQueue.append(mdrPackCommand(type: .ack, seq: 1, payload: Data()))
}

/// Decode all sent framed packets from mock transport.
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

/// Poll once, sending any pending data.
private func pump(_ hp: MDRHeadphones) {
    let _ = hp.pollEvents()
}

// MARK: - Command Queue Tests

@Suite("Command Queue")
struct CommandQueueTests {

    @Test func queueSingleCommandSendsImmediately() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        pump(hp)

        let cmds = decodeSentCommands(mock)
        #expect(cmds.count >= 1)
        #expect(cmds[0].data.first == T1Command.CONNECT_GET_PROTOCOL_INFO.rawValue)
    }

    @Test func queueMultipleCommandsSendsSequentially() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        hp.queueCommand(ConnectGetCapabilityInfo())
        hp.queueCommand(ConnectGetSupportFunction())
        pump(hp) // sends first command

        // Only first command should be sent
        let cmds1 = decodeSentCommands(mock)
        let dataCmds1 = cmds1.filter { $0.type == .dataMdr }
        #expect(dataCmds1.count == 1)
        #expect(dataCmds1[0].data.first == T1Command.CONNECT_GET_PROTOCOL_INFO.rawValue)

        // Inject ACK for first
        injectACK(mock)
        pump(hp) // processes ACK, sends second
        pump(hp) // ensure second is flushed

        let cmds2 = decodeSentCommands(mock)
        let dataCmds2 = cmds2.filter { $0.type == .dataMdr }
        #expect(dataCmds2.count == 2)
    }

    @Test func ackResumesQueue() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        hp.queueCommand(ConnectGetCapabilityInfo())
        pump(hp) // sends first

        // Inject ACK
        injectACK(mock)
        pump(hp) // processes ACK, dequeues second
        pump(hp) // sends second

        let cmds = decodeSentCommands(mock)
        let dataCmds = cmds.filter { $0.type == .dataMdr }
        #expect(dataCmds.count == 2)
        #expect(dataCmds[1].data.first == T1Command.CONNECT_GET_CAPABILITY_INFO.rawValue)
    }

    @Test func drainCallbackFiresWhenEmpty() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        hp.queueCommand(ConnectGetCapabilityInfo())

        var drained = false
        hp.setQueueDrainCallback { drained = true }

        pump(hp) // sends first
        #expect(drained == false)

        injectACK(mock)
        pump(hp) // ACK first, sends second
        pump(hp)
        #expect(drained == false)

        injectACK(mock)
        pump(hp) // ACK second, queue empty → drain fires
        #expect(drained == true)
    }

    @Test func drainCallbackFiresImmediatelyIfQueueEmpty() {
        let (hp, _) = makeHP()
        var drained = false
        hp.setQueueDrainCallback { drained = true }
        #expect(drained == true)
    }

    @Test func retryOnTimeout() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        pump(hp) // sends first

        let sentCountBefore = mock.sentData.count

        // Wait past timeout
        Thread.sleep(forTimeInterval: Double(MDRHeadphones.kAwaitTimeoutMS) / 1000.0 + 0.1)
        pump(hp) // moveNext detects timeout and re-enqueues into sendBuf
        pump(hp) // flushes sendBuf to transport

        #expect(mock.sentData.count > sentCountBefore)
    }

    @Test func retryMaxTimesMovesOn() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        hp.queueCommand(ConnectGetCapabilityInfo())
        pump(hp) // sends first

        // Exhaust all retries
        for _ in 0..<MDRHeadphones.kAwaitAckRetries {
            Thread.sleep(forTimeInterval: Double(MDRHeadphones.kAwaitTimeoutMS) / 1000.0 + 0.1)
            pump(hp)
        }

        // After max retries, queue should move to next command
        pump(hp)
        let cmds = decodeSentCommands(mock)
        let dataCmds = cmds.filter { $0.type == .dataMdr }
        // Should have sent: first (1) + retries (kAwaitAckRetries-1) + second (1)
        let hasCapInfo = dataCmds.contains { $0.data.first == T1Command.CONNECT_GET_CAPABILITY_INFO.rawValue }
        #expect(hasCapInfo == true)
    }

    @Test func queueCommandRawWorks() {
        let (hp, mock) = makeHP()
        let payload = Data([0x01, 0x02, 0x03])
        hp.queueCommandRaw(payload, type: .dataMdr)
        pump(hp)

        let cmds = decodeSentCommands(mock)
        #expect(cmds.count >= 1)
        #expect(cmds[0].data == payload)
    }

    @Test func nestedDrainCallbacks() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())

        var phase2Drained = false
        hp.setQueueDrainCallback { [hp] in
            // Phase 1 drained, queue more commands
            hp.queueCommand(ConnectGetCapabilityInfo())
            hp.setQueueDrainCallback {
                phase2Drained = true
            }
        }

        pump(hp) // sends first
        injectACK(mock)
        pump(hp) // ACK → drain fires → queues second
        pump(hp) // sends second
        #expect(phase2Drained == false)

        injectACK(mock)
        pump(hp) // ACK second → drain fires phase2
        #expect(phase2Drained == true)
    }

    @Test func queueDuringDrainCallback() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())

        var secondCommandSent = false
        hp.setQueueDrainCallback { [hp] in
            hp.queueCommand(ConnectGetSupportFunction())
            hp.setQueueDrainCallback {
                secondCommandSent = true
            }
        }

        pump(hp) // sends first
        injectACK(mock)
        pump(hp) // ACK → drain → queues support func
        pump(hp) // sends support func

        let cmds = decodeSentCommands(mock)
        let dataCmds = cmds.filter { $0.type == .dataMdr }
        let hasSupportCmd = dataCmds.contains { $0.data.first == T1Command.CONNECT_GET_SUPPORT_FUNCTION.rawValue }
        #expect(hasSupportCmd == true)

        injectACK(mock)
        pump(hp) // ACK → drain fires
        #expect(secondCommandSent == true)
    }

    @Test func multipleACKsIgnoreExtra() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        pump(hp) // sends first

        // Inject 2 ACKs
        injectACK(mock)
        injectACK(mock)
        pump(hp) // process first ACK
        pump(hp) // process second ACK (should be harmless)

        // Should not crash or cause issues
        let cmds = decodeSentCommands(mock)
        #expect(cmds.count >= 1)
    }

    @Test func queueWithDifferentDataTypes() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo()) // T1 = .dataMdr
        hp.queueCommand(T2ConnectGetSupportFunction(), type: .dataMdrNo2) // T2 = .dataMdrNo2
        pump(hp) // sends first (T1)

        injectACK(mock)
        pump(hp) // ACK → sends second (T2)
        pump(hp)

        let cmds = decodeSentCommands(mock)
        let t1Cmds = cmds.filter { $0.type == .dataMdr }
        let t2Cmds = cmds.filter { $0.type == .dataMdrNo2 }
        #expect(t1Cmds.count >= 1)
        #expect(t2Cmds.count >= 1)
    }

    @Test func queuePreservesCommandOrder() {
        let (hp, mock) = makeHP()
        hp.queueCommand(ConnectGetProtocolInfo())
        hp.queueCommand(ConnectGetCapabilityInfo())
        hp.queueCommand(ConnectGetSupportFunction())

        // Drain all with ACKs
        for _ in 0..<3 {
            pump(hp)
            injectACK(mock)
        }
        pump(hp)

        let cmds = decodeSentCommands(mock)
        let dataCmds = cmds.filter { $0.type == .dataMdr }
        #expect(dataCmds.count == 3)
        #expect(dataCmds[0].data.first == T1Command.CONNECT_GET_PROTOCOL_INFO.rawValue)
        #expect(dataCmds[1].data.first == T1Command.CONNECT_GET_CAPABILITY_INFO.rawValue)
        #expect(dataCmds[2].data.first == T1Command.CONNECT_GET_SUPPORT_FUNCTION.rawValue)
    }
}
