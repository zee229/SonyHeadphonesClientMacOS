import Testing
import Foundation
@testable import MDRProtocol

// MARK: - MDRProperty Tests

@Suite("MDRProperty")
struct MDRPropertyTests {
    @Test func initialValueClean() {
        let p = MDRProperty<Int>(42)
        #expect(p.desired == 42)
        #expect(p.current == 42)
        #expect(p.isDirty == false)
    }

    @Test func setDesiredMakesDirty() {
        var p = MDRProperty<Int>(0)
        p.desired = 5
        #expect(p.isDirty == true)
        #expect(p.desired == 5)
        #expect(p.current == 0)
    }

    @Test func commitMakesClean() {
        var p = MDRProperty<Int>(0)
        p.desired = 5
        p.commit()
        #expect(p.isDirty == false)
        #expect(p.current == 5)
    }

    @Test func overwriteSetsBeoth() {
        var p = MDRProperty<Int>(0)
        p.desired = 10
        p.overwrite(7)
        #expect(p.desired == 7)
        #expect(p.current == 7)
        #expect(p.isDirty == false)
    }

    @Test func boolProperty() {
        var p = MDRProperty<Bool>(false)
        #expect(p.isDirty == false)
        p.desired = true
        #expect(p.isDirty == true)
        p.overwrite(true)
        #expect(p.isDirty == false)
    }

    @Test func stringProperty() {
        var p = MDRProperty<String>("")
        p.desired = "hello"
        #expect(p.isDirty == true)
        p.commit()
        #expect(p.current == "hello")
    }

    @Test func arrayProperty() {
        var p = MDRProperty<[Int]>([])
        p.desired = [1, 2, 3]
        #expect(p.isDirty == true)
        p.commit()
        #expect(p.current == [1, 2, 3])
        #expect(p.isDirty == false)
    }

    @Test func equatable() {
        let a = MDRProperty<Int>(5)
        let b = MDRProperty<Int>(5)
        #expect(a == b)

        var c = MDRProperty<Int>(5)
        c.desired = 10
        #expect(a != c)
    }
}

// MARK: - MockTransport Tests

@Suite("MockTransport")
struct MockTransportTests {
    @Test func sendStoresData() throws {
        let mock = MockTransport()
        let data = Data([1, 2, 3])
        let sent = try mock.send(data)
        #expect(sent == 3)
        #expect(mock.sentData.count == 1)
        #expect(mock.sentData[0] == data)
    }

    @Test func receiveReturnsQueued() throws {
        let mock = MockTransport()
        let data = Data([10, 20, 30])
        mock.receiveQueue.append(data)
        let received = try mock.receive(maxLength: 100)
        #expect(received == data)
        #expect(mock.receiveQueue.isEmpty)
    }

    @Test func receiveReturnsEmptyWhenNoData() throws {
        let mock = MockTransport()
        let received = try mock.receive(maxLength: 100)
        #expect(received.isEmpty)
    }

    @Test func multipleSends() throws {
        let mock = MockTransport()
        _ = try mock.send(Data([1]))
        _ = try mock.send(Data([2]))
        #expect(mock.sentData.count == 2)
    }

    @Test func multipleReceives() throws {
        let mock = MockTransport()
        mock.receiveQueue.append(Data([1]))
        mock.receiveQueue.append(Data([2]))
        let first = try mock.receive(maxLength: 100)
        let second = try mock.receive(maxLength: 100)
        #expect(first == Data([1]))
        #expect(second == Data([2]))
    }
}

// MARK: - MDRHeadphones Send Tests

@Suite("MDRHeadphones Send")
struct MDRHeadphonesSendTests {
    @Test func sendCommandProducesPackedBytes() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        hp.sendCommand(ConnectGetProtocolInfo())

        // Trigger send via pollEvents
        let _ = hp.pollEvents()

        // Verify something was sent
        #expect(mock.sentData.count == 1)

        // Verify it's a valid packed command
        let sent = mock.sentData[0]
        #expect(sent.first == kStartMarker)
        #expect(sent.last == kEndMarker)

        // Verify it unpacks correctly
        let (result, unpacked) = mdrUnpackCommand(sent)
        #expect(result == .ok)
        #expect(unpacked != nil)
        #expect(unpacked!.type == .dataMdr)
    }

    @Test func sendCommandT2UsesDataMdrNo2() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        hp.sendCommand(T2ConnectGetSupportFunction(), type: .dataMdrNo2)
        let _ = hp.pollEvents()

        #expect(mock.sentData.count == 1)
        let (result, unpacked) = mdrUnpackCommand(mock.sentData[0])
        #expect(result == .ok)
        #expect(unpacked!.type == .dataMdrNo2)
    }

    @Test func sendCommandPayloadMatchesManualSerialization() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let cmd = ConnectGetProtocolInfo()
        hp.sendCommand(cmd)
        let _ = hp.pollEvents()

        // Manual serialization
        var writer = DataWriter()
        cmd.serialize(to: &writer)
        let expected = mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data)

        #expect(mock.sentData[0] == expected)
    }

    @Test func multipleSendsQueue() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        hp.sendCommand(ConnectGetProtocolInfo())
        hp.sendCommand(ConnectGetCapabilityInfo())
        let _ = hp.pollEvents()

        // Both should be sent (concatenated as one data chunk or two separate sends)
        let totalSent = mock.sentData.reduce(0) { $0 + $1.count }
        #expect(totalSent > 0)
    }
}

// MARK: - MDRHeadphones PollEvents Tests

@Suite("MDRHeadphones PollEvents")
struct MDRHeadphonesPollEventsTests {
    @Test func idleWhenNothingToDo() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)
        let event = hp.pollEvents()
        #expect(event == MDREvent.idle.rawValue)
    }

    @Test func processesACK() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        // Inject ACK packet
        let ack = mdrPackCommand(type: .ack, seq: 0, payload: Data())
        mock.receiveQueue.append(ack)

        let event = hp.pollEvents()
        // ACK returns unhandled since there's no meaningful event from it
        #expect(event == MDREvent.unhandled.rawValue)
    }

    @Test func ackResumesAwaiter() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        var ackResult: Int? = nil
        hp.setAwaiter(.ack) { result in
            ackResult = result
        }

        // Inject ACK
        let ack = mdrPackCommand(type: .ack, seq: 0, payload: Data())
        mock.receiveQueue.append(ack)
        let _ = hp.pollEvents()

        #expect(ackResult == 0)
    }

    @Test func processesProtocolInfo() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        // Create ConnectRetProtocolInfo response
        let response = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        let packed = mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data)
        mock.receiveQueue.append(packed)

        let event = hp.pollEvents()
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.protocolInfo.version == 2)
        #expect(hp.protocolInfo.hasTable1 == true)
        #expect(hp.protocolInfo.hasTable2 == true)
    }

    @Test func protocolInfoResumesAwaiter() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        var awaiterFired = false
        hp.setAwaiter(.protocolInfo) { _ in
            awaiterFired = true
        }

        let response = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let _ = hp.pollEvents()
        #expect(awaiterFired == true)
    }

    @Test func sendsACKForDataMdr() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        // First pollEvents processes the command (receives data, processes, queues ACK in sendBuf)
        let _ = hp.pollEvents()
        // Second pollEvents sends the ACK
        let _ = hp.pollEvents()

        // Check that an ACK was sent
        #expect(mock.sentData.count >= 1)
        let sentACK = mock.sentData[0]
        let (result, unpacked) = mdrUnpackCommand(sentACK)
        #expect(result == .ok)
        #expect(unpacked!.type == .ack)
        #expect(unpacked!.seq == 1) // ACK seq = 1 - received_seq
    }
}

// MARK: - MDRHeadphones Handler Tests

@Suite("MDRHeadphones Handlers")
struct MDRHeadphonesHandlerTests {
    @Test func supportFunctionT1() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        // Build ConnectRetSupportFunction with a few entries
        let entries = [
            SupportFunctionEntry(rawFunction: 0x10, priority: 1),
            SupportFunctionEntry(rawFunction: 0x20, priority: 2),
        ]
        let response = ConnectRetSupportFunction(supportFunctions: entries)
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.supportFunctions.rawValue)
        #expect(hp.support.table1Functions[0x10] == true)
        #expect(hp.support.table1Functions[0x20] == true)
        #expect(hp.support.table1Functions[0x30] == false)
    }

    @Test func supportFunctionT2() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let entries = [
            SupportFunctionEntry(rawFunction: 0x05, priority: 1),
        ]
        let response = T2ConnectRetSupportFunction(supportFunctions: entries)
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdrNo2, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.supportFunctions.rawValue)
        #expect(hp.support.table2Functions[0x05] == true)
    }

    @Test func capabilityInfo() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = ConnectRetCapabilityInfo(uniqueID: PrefixedString("AA:BB:CC:DD:EE:FF"))
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.ok.rawValue)
        #expect(hp.uniqueId == "AA:BB:CC:DD:EE:FF")
    }

    @Test func deviceInfoModelName() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = ConnectRetDeviceInfoModelName(
            value: PrefixedString("WH-1000XM5")
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.deviceInfo.rawValue)
        #expect(hp.modelName == "WH-1000XM5")
    }

    @Test func deviceInfoFwVersion() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = ConnectRetDeviceInfoFwVersion(
            value: PrefixedString("3.0.1")
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.deviceInfo.rawValue)
        #expect(hp.fwVersion == "3.0.1")
    }

    @Test func deviceInfoSeriesAndColor() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = ConnectRetDeviceInfoSeriesAndColor(
            series: .EXTRA_BASS,
            color: .BLACK
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.deviceInfo.rawValue)
        #expect(hp.modelSeries == .EXTRA_BASS)
        #expect(hp.modelColor == .BLACK)
    }

    @Test func batteryStatus() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = PowerRetStatusBattery(
            batteryStatus: PowerBatteryStatus(
                batteryLevel: 85,
                chargingStatus: .CHARGING
            )
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.battery.rawValue)
        #expect(hp.batteryL.level == 85)
        #expect(hp.batteryL.charging == .CHARGING)
        #expect(hp.batteryL.threshold == 0xFF)
    }

    @Test func leftRightBatteryStatus() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = PowerRetStatusLeftRightBattery(
            batteryStatus: PowerLeftRightBatteryStatus(
                leftBatteryLevel: 90,
                leftChargingStatus: .NOT_CHARGING,
                rightBatteryLevel: 80,
                rightChargingStatus: .CHARGING
            )
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.battery.rawValue)
        #expect(hp.batteryL.level == 90)
        #expect(hp.batteryL.charging == .NOT_CHARGING)
        #expect(hp.batteryR.level == 80)
        #expect(hp.batteryR.charging == .CHARGING)
    }

    @Test func cradleBatteryStatus() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        let response = PowerRetStatusCradleBattery(
            batteryStatus: PowerBatteryStatus(
                batteryLevel: 50,
                chargingStatus: .CHARGING
            )
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.battery.rawValue)
        #expect(hp.batteryCase.level == 50)
    }
}

// MARK: - IsDirty Tests

@Suite("MDRHeadphones IsDirty")
struct MDRHeadphonesIsDirtyTests {
    @Test func cleanByDefault() {
        let hp = MDRHeadphones(transport: MockTransport())
        #expect(hp.isDirty == false)
    }

    @Test func dirtyWhenPropertyChanged() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.ncAsmEnabled.desired = true
        #expect(hp.isDirty == true)
    }

    @Test func cleanAfterOverwrite() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.ncAsmEnabled.desired = true
        hp.ncAsmEnabled.overwrite(false)
        #expect(hp.isDirty == false)
    }

    @Test func dirtyMultipleProperties() {
        let hp = MDRHeadphones(transport: MockTransport())
        hp.playVolume.desired = 10
        hp.eqPresetId.desired = .BRIGHT
        #expect(hp.isDirty == true)
        hp.playVolume.commit()
        #expect(hp.isDirty == true) // eqPresetId still dirty
        hp.eqPresetId.commit()
        #expect(hp.isDirty == false)
    }
}

// MARK: - Timeout Tests

@Suite("MDRHeadphones Timeout")
struct MDRHeadphonesTimeoutTests {
    @Test func awaiterTimesOut() throws {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        var awaiterResult: Int? = nil
        hp.setAwaiter(.ack) { result in
            awaiterResult = result
        }

        // Verify awaiter is active
        #expect(hp.hasActiveAwaiter(.ack) == true)

        // Sleep past the timeout (we use a tight loop checking)
        // In practice, we just need moveNext/pollEvents to detect the timeout
        // For testing, we simulate by waiting
        Thread.sleep(forTimeInterval: Double(MDRHeadphones.kAwaitTimeoutMS) / 1000.0 + 0.1)

        let _ = hp.pollEvents()

        // Awaiter should have timed out with result -1
        #expect(awaiterResult == -1)
        #expect(hp.hasActiveAwaiter(.ack) == false)
    }
}

// MARK: - IsReady Tests

@Suite("MDRHeadphones IsReady")
struct MDRHeadphonesIsReadyTests {
    @Test func readyByDefault() {
        let hp = MDRHeadphones(transport: MockTransport())
        #expect(hp.isReady == true)
    }
}

// MARK: - End-to-end roundtrip

@Suite("MDRHeadphones Roundtrip")
struct MDRHeadphonesRoundtripTests {
    @Test func sendCommandAndReceiveResponse() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        // 1. Send ConnectGetProtocolInfo
        hp.sendCommand(ConnectGetProtocolInfo())
        let _ = hp.pollEvents() // Sends the command

        // Verify command was sent
        #expect(mock.sentData.count == 1)

        // 2. Inject ConnectRetProtocolInfo response
        let response = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))

        let event = hp.pollEvents()
        #expect(event == MDREvent.ok.rawValue)

        // 3. Verify state was updated
        #expect(hp.protocolInfo.version == 2)
        #expect(hp.protocolInfo.hasTable1 == true)
        #expect(hp.protocolInfo.hasTable2 == true)

        // 4. Verify ACK was queued (will be sent on next poll)
        let _ = hp.pollEvents()
        // The ACK should have been sent (sentData[0] was the command, sentData[1] is the ACK)
        #expect(mock.sentData.count >= 2)
    }

    @Test func fullProtocolInfoHandshake() {
        let mock = MockTransport()
        let hp = MDRHeadphones(transport: mock)

        // Set up protocol info awaiter
        var protocolInfoReceived = false
        hp.setAwaiter(.protocolInfo) { _ in
            protocolInfoReceived = true
        }

        // Send request
        hp.sendCommand(ConnectGetProtocolInfo())
        let _ = hp.pollEvents()

        // Inject response
        let response = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        mock.receiveQueue.append(mdrPackCommand(type: .dataMdr, seq: 0, payload: writer.data))
        let _ = hp.pollEvents()

        #expect(protocolInfoReceived == true)
        #expect(hp.protocolInfo.version == 2)
    }
}

// MARK: - Transport Error Handling

private struct TransportError: Error {}

private final class ThrowingMockTransport: MDRTransport {
    var sentData: [Data] = []
    var receiveQueue: [Data] = []
    var shouldThrowOnSend = false
    var shouldThrowOnReceive = false

    func send(_ data: Data) throws -> Int {
        if shouldThrowOnSend { throw TransportError() }
        sentData.append(data)
        return data.count
    }

    func receive(maxLength: Int) throws -> Data {
        if shouldThrowOnReceive { throw TransportError() }
        if receiveQueue.isEmpty { return Data() }
        return receiveQueue.removeFirst()
    }
}

@Suite("Transport Error Handling")
struct TransportErrorHandlingTests {

    // MARK: - Helpers

    private func makeHP(transport: MDRTransport) -> MDRHeadphones {
        MDRHeadphones(transport: transport)
    }

    private func makeProtocolInfoPacket(seq: UInt8 = 0) -> Data {
        let response = ConnectRetProtocolInfo(
            protocolVersion: Int32BE(2),
            supportTable1Value: .ENABLE,
            supportTable2Value: .ENABLE
        )
        var writer = DataWriter()
        response.serialize(to: &writer)
        return mdrPackCommand(type: .dataMdr, seq: seq, payload: writer.data)
    }

    // MARK: - Tests

    @Test func pollEventsReturnsErrorWhenReceiveThrows() {
        let transport = ThrowingMockTransport()
        let hp = makeHP(transport: transport)

        transport.shouldThrowOnReceive = true
        let event = hp.pollEvents()

        #expect(event == MDREvent.error.rawValue)
    }

    @Test func pollEventsReturnsErrorWhenSendThrows() {
        let transport = ThrowingMockTransport()
        let hp = makeHP(transport: transport)

        // Queue a command so sendBuf has data to send
        hp.sendCommand(ConnectGetProtocolInfo())

        // Now make send throw before pollEvents tries to flush sendBuf
        transport.shouldThrowOnSend = true
        let event = hp.pollEvents()

        #expect(event == MDREvent.error.rawValue)
    }

    @Test func badChecksumPacketDiscarded() {
        let mock = MockTransport()
        let hp = makeHP(transport: mock)

        // Build a valid packet, then corrupt the checksum
        var validPacket = makeProtocolInfoPacket()
        // The checksum is the last byte before kEndMarker in the escaped content.
        // Corrupt a byte inside the packet (between START and END) to break checksum.
        // The escaped content starts at index 1, ends at index count-2.
        // Flip a bit in the middle of the packet.
        let corruptIdx = validPacket.count / 2
        validPacket[corruptIdx] ^= 0xFF

        mock.receiveQueue.append(validPacket)
        let event = hp.pollEvents()

        // Bad checksum should be discarded; not a crash, returns idle
        #expect(event == MDREvent.idle.rawValue)

        // The hp should still work: inject a valid packet and process it
        mock.receiveQueue.append(makeProtocolInfoPacket())
        let event2 = hp.pollEvents()
        #expect(event2 == MDREvent.ok.rawValue)
        #expect(hp.protocolInfo.version == 2)
    }

    @Test func incompletePacketStaysInBuffer() {
        let mock = MockTransport()
        let hp = makeHP(transport: mock)

        // Build a valid packet, then split it into two parts
        let fullPacket = makeProtocolInfoPacket()
        let splitPoint = fullPacket.count / 2
        let firstHalf = Data(fullPacket[..<splitPoint])
        let secondHalf = Data(fullPacket[splitPoint...])

        // Inject first half (has START but no END)
        mock.receiveQueue.append(firstHalf)
        let event1 = hp.pollEvents()
        #expect(event1 == MDREvent.idle.rawValue)

        // Inject second half (has END)
        mock.receiveQueue.append(secondHalf)
        let event2 = hp.pollEvents()
        #expect(event2 == MDREvent.ok.rawValue)
        #expect(hp.protocolInfo.version == 2)
    }

    @Test func multipleConcatenatedPackets() {
        let mock = MockTransport()
        let hp = makeHP(transport: mock)

        // Build two different valid packets
        let packet1 = makeProtocolInfoPacket(seq: 0)

        let deviceInfoResponse = ConnectRetDeviceInfoModelName(
            value: PrefixedString("WH-1000XM5")
        )
        var writer2 = DataWriter()
        deviceInfoResponse.serialize(to: &writer2)
        let packet2 = mdrPackCommand(type: .dataMdr, seq: 1, payload: writer2.data)

        // Concatenate both packets into a single receiveQueue entry
        var combined = Data()
        combined.append(packet1)
        combined.append(packet2)
        mock.receiveQueue.append(combined)

        // First pollEvents should process the first packet
        let event1 = hp.pollEvents()
        #expect(event1 == MDREvent.ok.rawValue)
        #expect(hp.protocolInfo.version == 2)

        // Second pollEvents should process the second packet
        let event2 = hp.pollEvents()
        #expect(event2 == MDREvent.deviceInfo.rawValue)
        #expect(hp.modelName == "WH-1000XM5")
    }
}
