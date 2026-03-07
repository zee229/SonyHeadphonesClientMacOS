import Foundation

/// Main state machine for Sony headphones MDR protocol.
/// Mirrors C++ `MDRHeadphones` from Headphones.hpp.
///
/// Usage: create with a transport, call `pollEvents()` in a timer loop,
/// and use `invoke()` to schedule tasks (init/sync/commit).
///
/// Not thread-safe. Must be used from a single thread (typically main).
public final class MDRHeadphones {
    // MARK: - Constants

    public static let kAwaitAckRetries = 5
    public static let kAwaitTimeoutMS = 1000

    // MARK: - Awaiter

    public enum AwaitType: Int, CaseIterable, Sendable {
        case ack = 0
        case protocolInfo = 1
        case supportFunction = 2
    }

    public typealias AwaiterCallback = (Int) -> Void

    private struct Awaiter {
        var callback: AwaiterCallback?
        var timestamp: ContinuousClock.Instant = .now
        var isActive: Bool { callback != nil }
    }

    // MARK: - Transport

    private let transport: MDRTransport

    // MARK: - Internal buffers

    private var recvBuf = Data()
    private var sendBuf = Data()
    public private(set) var seqNumber: UInt8 = 0

    // MARK: - Awaiter state

    private var awaiters: [AwaitType: Awaiter] = [:]

    // MARK: - Command Queue (sequential send with ACK gating)

    private struct QueuedCommand {
        let payload: Data
        let type: MDRDataType
    }

    private var commandQueue: [QueuedCommand] = []
    private var awaitingQueueACK = false
    private var queueACKTimestamp: ContinuousClock.Instant = .now
    private var queueACKRetries = 0
    private var lastQueuedPayload: Data?
    private var lastQueuedType: MDRDataType?
    private var queueDrainCallback: (() -> Void)?

    // MARK: - Task state

    private var taskRunning = false
    private var taskResult: Int?
    private var taskError: Error?

    // MARK: - Error

    public private(set) var lastError: String = "N/A"

    // MARK: - Protocol State

    public struct ProtocolStates: Equatable, Sendable {
        public var version: Int = 0
        public var hasTable1: Bool = false
        public var hasTable2: Bool = false
    }
    public var protocolInfo = ProtocolStates()

    // MARK: - Support Functions

    public struct SupportStates: Equatable, Sendable {
        public var table1Functions: [Bool] = Array(repeating: false, count: 256)
        public var table2Functions: [Bool] = Array(repeating: false, count: 256)

        public func contains(_ f: MessageMdrV2FunctionType_Table1) -> Bool {
            table1Functions[Int(f.rawValue)]
        }

        public func contains(_ f: MessageMdrV2FunctionType_Table2) -> Bool {
            table2Functions[Int(f.rawValue)]
        }
    }
    public var support = SupportStates()

    // MARK: - Device Info

    public var uniqueId: String = ""
    public var fwVersion: String = ""
    public var modelName: String = ""
    public var modelSeries: ModelSeriesType = .NO_SERIES
    public var modelColor: ModelColor = .DEFAULT
    public var audioCodec: AudioCodec = .UNSETTLED

    // MARK: - Alerts & Logs

    public var lastAlertMessage: AlertMessageType = .DISCONNECT_CAUSED_BY_CONNECTION_MODE_CHANGE
    public var lastInteractionMessage: String = ""
    public var lastDeviceJSONMessage: String = ""

    // MARK: - Paired Devices

    public struct PeripheralDevice: Equatable, Sendable {
        public var macAddress: String
        public var name: String
        public var connected: Bool
    }
    public var pairedDevices: [PeripheralDevice] = []
    public var pairedDevicesPlaybackDeviceID: UInt8 = 0

    // MARK: - Safe Listening

    public var safeListeningSoundPressure: Int = 0

    // MARK: - Battery

    public struct BatteryState: Equatable, Sendable {
        public var level: UInt8 = 0
        public var threshold: UInt8 = 0
        public var charging: BatteryChargingStatus = .NOT_CHARGING
    }
    public var batteryL = BatteryState()
    public var batteryR = BatteryState()
    public var batteryCase = BatteryState()

    // MARK: - Playback

    public var playTrackTitle: String = ""
    public var playTrackAlbum: String = ""
    public var playTrackArtist: String = ""
    public var playPause: PlaybackStatus = .UNSETTLED

    // MARK: - Upscaling

    public var upscalingType: UpscalingType = .DSEE_HX
    public var upscalingAvailable: Bool = false

    // MARK: - General Settings Capability

    public struct GsCapability: Equatable, Sendable {
        public var type: GsSettingType = .BOOLEAN_TYPE
        public var value: GsSettingInfo = GsSettingInfo()
    }
    public var gsCapability1 = GsCapability()
    public var gsCapability2 = GsCapability()
    public var gsCapability3 = GsCapability()
    public var gsCapability4 = GsCapability()

    // MARK: - MDRProperty Fields

    public var shutdown = MDRProperty<Bool>(false)

    public var ncAsmEnabled = MDRProperty<Bool>(false)
    public var ncAsmFocusOnVoice = MDRProperty<Bool>(false)
    public var ncAsmAmbientLevel = MDRProperty<Int>(0)
    public var ncAsmButtonFunction = MDRProperty<Function>(.NO_FUNCTION)
    public var ncAsmMode = MDRProperty<NcAsmMode>(.NC)
    public var ncAsmAutoAsmEnabled = MDRProperty<Bool>(false)
    public var ncAsmNoiseAdaptiveSensitivity = MDRProperty<NoiseAdaptiveSensitivity>(.STANDARD)

    public var powerAutoOff = MDRProperty<AutoPowerOffElements>(.POWER_OFF_DISABLE)
    public var powerAutoOffWearingDetection = MDRProperty<AutoPowerOffWearingDetectionElements>(.POWER_OFF_DISABLE)

    public var playVolume = MDRProperty<Int>(0)
    public var playControl = MDRProperty<PlaybackControl>(.KEY_OFF)

    public var gsParamBool1 = MDRProperty<Bool>(false)
    public var gsParamBool2 = MDRProperty<Bool>(false)
    public var gsParamBool3 = MDRProperty<Bool>(false)
    public var gsParamBool4 = MDRProperty<Bool>(false)

    public var upscalingEnabled = MDRProperty<Bool>(false)

    public var audioPriorityMode = MDRProperty<PriorMode>(.SOUND_QUALITY_PRIOR)
    public var bgmModeEnabled = MDRProperty<Bool>(false)
    public var bgmModeRoomSize = MDRProperty<RoomSize>(.SMALL)
    public var upmixCinemaEnabled = MDRProperty<Bool>(false)
    public var autoPauseEnabled = MDRProperty<Bool>(false)

    public var touchFunctionLeft = MDRProperty<Preset>(.NO_FUNCTION)
    public var touchFunctionRight = MDRProperty<Preset>(.NO_FUNCTION)

    public var speakToChatEnabled = MDRProperty<Bool>(false)
    public var speakToChatDetectSensitivity = MDRProperty<DetectSensitivity>(.AUTO)
    public var speakToModeOutTime = MDRProperty<ModeOutTime>(.MID)

    public var headGestureEnabled = MDRProperty<Bool>(false)

    public var eqAvailable = MDRProperty<Bool>(false)
    public var eqPresetId = MDRProperty<EqPresetId>(.OFF)
    public var eqClearBass = MDRProperty<Int>(0)
    public var eqConfig = MDRProperty<[Int]>([])

    public var voiceGuidanceEnabled = MDRProperty<Bool>(false)
    public var voiceGuidanceVolume = MDRProperty<Int>(0)

    public var pairingMode = MDRProperty<Bool>(false)

    public var multipointDeviceMac = MDRProperty<String>("")
    public var pairedDeviceDisconnectMac = MDRProperty<String>("")
    public var pairedDeviceConnectMac = MDRProperty<String>("")
    public var pairedDeviceUnpairMac = MDRProperty<String>("")

    public var safeListeningPreviewMode = MDRProperty<Bool>(false)

    // MARK: - Init

    public init(transport: MDRTransport) {
        self.transport = transport
    }

    // MARK: - Public API

    /// Main event loop. Call from a timer (e.g. 60fps).
    /// Returns an MDREvent raw value.
    public func pollEvents() -> Int {
        // Send pending data
        if !sendBuf.isEmpty {
            do {
                let toSend = min(sendBuf.count, kMDRMaxPacketSize)
                let sent = try transport.send(Data(sendBuf.prefix(toSend)))
                if sent > 0 {
                    sendBuf.removeFirst(sent)
                }
            } catch {
                return MDREvent.error.rawValue
            }
        }

        // Receive data
        do {
            let data = try transport.receive(maxLength: kMDRMaxPacketSize)
            if !data.isEmpty {
                recvBuf.append(data)
            }
        } catch {
            return MDREvent.error.rawValue
        }

        return moveNext()
    }

    /// Check if a task is currently running.
    public var isReady: Bool { !taskRunning }

    /// Check if any property is dirty.
    public var isDirty: Bool {
        shutdown.isDirty || ncAsmEnabled.isDirty || ncAsmFocusOnVoice.isDirty ||
        ncAsmAmbientLevel.isDirty || ncAsmButtonFunction.isDirty || ncAsmMode.isDirty ||
        ncAsmAutoAsmEnabled.isDirty || ncAsmNoiseAdaptiveSensitivity.isDirty ||
        powerAutoOff.isDirty || powerAutoOffWearingDetection.isDirty ||
        playVolume.isDirty || playControl.isDirty ||
        gsParamBool1.isDirty || gsParamBool2.isDirty ||
        gsParamBool3.isDirty || gsParamBool4.isDirty ||
        upscalingEnabled.isDirty || audioPriorityMode.isDirty ||
        bgmModeEnabled.isDirty || bgmModeRoomSize.isDirty ||
        upmixCinemaEnabled.isDirty || autoPauseEnabled.isDirty ||
        touchFunctionLeft.isDirty || touchFunctionRight.isDirty ||
        speakToChatEnabled.isDirty || speakToChatDetectSensitivity.isDirty ||
        speakToModeOutTime.isDirty || headGestureEnabled.isDirty ||
        eqAvailable.isDirty || eqPresetId.isDirty || eqClearBass.isDirty ||
        eqConfig.isDirty || voiceGuidanceEnabled.isDirty || voiceGuidanceVolume.isDirty ||
        pairingMode.isDirty || multipointDeviceMac.isDirty ||
        safeListeningPreviewMode.isDirty ||
        pairedDeviceConnectMac.isDirty || pairedDeviceDisconnectMac.isDirty ||
        pairedDeviceUnpairMac.isDirty
    }

    // MARK: - Send Commands

    /// Serialize and pack a command, enqueuing it for sending.
    public func sendCommand<T: MDRSerializable>(_ command: T, type: MDRDataType = .dataMdr) {
        var writer = DataWriter()
        command.serialize(to: &writer)
        sendCommandRaw(writer.data, type: type)
    }

    /// Pack raw payload bytes and enqueue for sending.
    public func sendCommandRaw(_ payload: Data, type: MDRDataType, seq: UInt8? = nil) {
        let s = seq ?? seqNumber
        let packed = mdrPackCommand(type: type, seq: s, payload: payload)
        sendBuf.append(packed)
    }

    /// Send an ACK for the given sequence number.
    private func sendACK(seq: UInt8) {
        sendCommandRaw(Data(), type: .ack, seq: 1 - seq)
    }

    // MARK: - Command Queue

    /// Queue a command for sequential sending (waits for ACK between each).
    public func queueCommand<T: MDRSerializable>(_ command: T, type: MDRDataType = .dataMdr) {
        var writer = DataWriter()
        command.serialize(to: &writer)
        queueCommandRaw(writer.data, type: type)
    }

    /// Queue raw payload for sequential sending.
    public func queueCommandRaw(_ payload: Data, type: MDRDataType) {
        commandQueue.append(QueuedCommand(payload: payload, type: type))
        processQueue()
    }

    /// Set a callback to fire when the queue is fully drained (all ACKs received).
    public func setQueueDrainCallback(_ callback: @escaping () -> Void) {
        queueDrainCallback = callback
        if commandQueue.isEmpty && !awaitingQueueACK {
            let cb = queueDrainCallback
            queueDrainCallback = nil
            cb?()
        }
    }

    private func processQueue() {
        guard !awaitingQueueACK, !commandQueue.isEmpty else { return }
        let cmd = commandQueue.removeFirst()
        awaitingQueueACK = true
        queueACKRetries = 0
        queueACKTimestamp = .now
        lastQueuedPayload = cmd.payload
        lastQueuedType = cmd.type
        sendCommandRaw(cmd.payload, type: cmd.type)
    }

    private func onQueueACKReceived() {
        awaitingQueueACK = false
        lastQueuedPayload = nil
        lastQueuedType = nil
        if commandQueue.isEmpty {
            let cb = queueDrainCallback
            queueDrainCallback = nil
            cb?()
        } else {
            processQueue()
        }
    }

    private func checkQueueACKTimeout() {
        guard awaitingQueueACK, let payload = lastQueuedPayload, let type = lastQueuedType else { return }
        if ContinuousClock.now - queueACKTimestamp > .milliseconds(Self.kAwaitTimeoutMS) {
            queueACKRetries += 1
            if queueACKRetries < Self.kAwaitAckRetries {
                queueACKTimestamp = .now
                sendCommandRaw(payload, type: type)
            } else {
                awaitingQueueACK = false
                lastQueuedPayload = nil
                lastQueuedType = nil
                processQueue()
            }
        }
    }

    // MARK: - Awaiter API

    /// Set up an awaiter callback. When the awaiter type fires, callback is called with result.
    public func setAwaiter(_ type: AwaitType, callback: @escaping AwaiterCallback) {
        awaiters[type] = Awaiter(callback: callback, timestamp: ContinuousClock.now)
    }

    /// Resume an awaiter with the given result.
    public func awake(_ type: AwaitType, result: Int = 0) {
        guard let awaiter = awaiters[type] else { return }
        awaiters[type] = nil
        awaiter.callback?(result)
    }

    /// Check if an awaiter of the given type is active.
    public func hasActiveAwaiter(_ type: AwaitType) -> Bool {
        awaiters[type]?.isActive ?? false
    }

    /// Async await wrapper — suspends until the awaiter fires.
    public func awaitType(_ type: AwaitType) async -> Int {
        await withCheckedContinuation { cont in
            setAwaiter(type) { result in
                cont.resume(returning: result)
            }
        }
    }

    /// Send a command and await ACK with retries and timeout.
    public func sendCommandACK<T: MDRSerializable>(_ command: T, type: MDRDataType = .dataMdr) async throws {
        for retry in 0..<Self.kAwaitAckRetries {
            sendCommand(command, type: type)
            let result = await awaitType(.ack)
            if result == 0 { return }
            if retry < Self.kAwaitAckRetries - 1 {
                continue
            }
        }
        throw MDRError.timeout
    }

    // MARK: - Task Management

    /// Mark a task as running. Used by request functions (Iter 6).
    public func setTaskRunning(_ running: Bool) {
        taskRunning = running
    }

    /// Set the task completion result. Called when a task finishes.
    public func setTaskResult(_ result: Int) {
        taskResult = result
        taskRunning = false
    }

    /// Set the task error. Called when a task fails.
    public func setTaskError(_ error: Error) {
        taskError = error
        taskRunning = false
    }

    // MARK: - MoveNext (internal)

    private func moveNext() -> Int {
        // Check awaiter timeouts
        let now = ContinuousClock.now
        for type in AwaitType.allCases {
            guard let awaiter = awaiters[type], awaiter.isActive else { continue }
            if now - awaiter.timestamp > .milliseconds(Self.kAwaitTimeoutMS) {
                awake(type, result: -1)
            }
        }

        // Check queue ACK timeouts
        checkQueueACKTimeout()

        // Check completed task
        if let result = taskResult {
            taskResult = nil
            return result
        }
        if let error = taskError {
            taskError = nil
            lastError = error.localizedDescription
            return MDREvent.error.rawValue
        }

        let idleCode = taskRunning ? MDREvent.inProgress.rawValue : MDREvent.idle.rawValue

        guard !recvBuf.isEmpty else { return idleCode }

        // Find complete command in buffer: <START> ... <END>
        guard let startIdx = recvBuf.firstIndex(of: kStartMarker) else {
            return idleCode
        }
        let searchRange = recvBuf.index(after: startIdx)..<recvBuf.endIndex
        guard let endIdx = recvBuf[searchRange].firstIndex(of: kEndMarker) else {
            return idleCode
        }

        let commandData = Data(recvBuf[startIdx...endIdx])
        let (result, unpacked) = mdrUnpackCommand(commandData)

        switch result {
        case .ok:
            recvBuf.removeSubrange(recvBuf.startIndex...endIdx)
            guard let cmd = unpacked else { return idleCode }
            return handle(cmd.data, type: cmd.type, seq: cmd.seq)
        case .incomplete:
            break
        case .badMarker, .badChecksum:
            recvBuf.removeSubrange(recvBuf.startIndex...endIdx)
        }

        return idleCode
    }

    // MARK: - Handle Dispatch

    private func handle(_ data: Data, type: MDRDataType, seq: UInt8) -> Int {
        seqNumber = seq
        switch type {
        case .ack:
            handleACK(seq)
            return MDREvent.unhandled.rawValue
        case .dataMdr:
            sendACK(seq: seq)
            return handleCommandV2T1(data)
        case .dataMdrNo2:
            sendACK(seq: seq)
            return handleCommandV2T2(data)
        default:
            return MDREvent.unhandled.rawValue
        }
    }

    private func handleACK(_ seq: UInt8) {
        if awaitingQueueACK {
            onQueueACKReceived()
        }
        awake(.ack)
    }

    // MARK: - T1 Command Handler

    /// Dispatch T1 commands by command byte.
    func handleCommandV2T1(_ data: Data) -> Int {
        guard !data.isEmpty else { return MDREvent.unhandled.rawValue }
        let commandByte = data[data.startIndex]
        guard let command = T1Command(rawValue: commandByte) else {
            return MDREvent.unhandled.rawValue
        }

        switch command {
        case .CONNECT_RET_PROTOCOL_INFO:
            return handleProtocolInfoT1(data)
        case .CONNECT_RET_SUPPORT_FUNCTION:
            return handleSupportFunctionT1(data)
        case .CONNECT_RET_CAPABILITY_INFO:
            return handleCapabilityInfoT1(data)
        case .CONNECT_RET_DEVICE_INFO:
            return handleDeviceInfoT1(data)
        case .COMMON_RET_STATUS, .COMMON_NTFY_STATUS:
            return handleCommonStatusT1(data)
        case .NCASM_RET_PARAM, .NCASM_NTFY_PARAM:
            return handleNcAsmParamT1(data)
        case .POWER_RET_STATUS, .POWER_NTFY_STATUS:
            return handlePowerStatusT1(data)
        case .PLAY_RET_PARAM, .PLAY_NTFY_PARAM:
            return handlePlayParamT1(data)
        case .POWER_RET_PARAM, .POWER_NTFY_PARAM:
            return handlePowerParamT1(data)
        case .PLAY_RET_STATUS, .PLAY_NTFY_STATUS:
            return handlePlaybackStatusT1(data)
        case .GENERAL_SETTING_RET_CAPABILITY:
            return handleGsCapabilityT1(data)
        case .GENERAL_SETTING_RET_PARAM, .GENERAL_SETTING_NTFY_PARAM:
            return handleGsParamT1(data)
        case .AUDIO_RET_CAPABILITY:
            return handleAudioCapabilityT1(data)
        case .AUDIO_RET_STATUS, .AUDIO_NTFY_STATUS:
            return handleAudioStatusT1(data)
        case .AUDIO_RET_PARAM, .AUDIO_NTFY_PARAM:
            return handleAudioParamT1(data)
        case .SYSTEM_RET_PARAM, .SYSTEM_NTFY_PARAM:
            return handleSystemParamT1(data)
        case .SYSTEM_RET_EXT_PARAM, .SYSTEM_NTFY_EXT_PARAM:
            return handleSystemExtParamT1(data)
        case .EQEBB_RET_STATUS, .EQEBB_NTFY_STATUS:
            return handleEqEbbStatusT1(data)
        case .EQEBB_RET_PARAM, .EQEBB_NTFY_PARAM:
            return handleEqEbbParamT1(data)
        case .ALERT_NTFY_PARAM:
            return handleAlertParamT1(data)
        case .LOG_NTFY_PARAM:
            return handleLogParamT1(data)
        default:
            return MDREvent.unhandled.rawValue
        }
    }

    // MARK: - T2 Command Handler

    /// Dispatch T2 commands by command byte.
    func handleCommandV2T2(_ data: Data) -> Int {
        guard !data.isEmpty else { return MDREvent.unhandled.rawValue }
        let commandByte = data[data.startIndex]
        guard let command = T2Command(rawValue: commandByte) else {
            return MDREvent.unhandled.rawValue
        }

        switch command {
        case .CONNECT_RET_SUPPORT_FUNCTION:
            return handleSupportFunctionT2(data)
        case .VOICE_GUIDANCE_RET_PARAM, .VOICE_GUIDANCE_NTFY_PARAM:
            return handleVoiceGuidanceParamT2(data)
        case .PERI_RET_STATUS, .PERI_NTFY_STATUS:
            return handlePeripheralStatusT2(data)
        case .PERI_NTFY_EXTENDED_PARAM:
            return handlePeripheralNotifyExtendedParamT2(data)
        case .PERI_RET_PARAM, .PERI_NTFY_PARAM:
            return handlePeripheralParamT2(data)
        case .SAFE_LISTENING_NTFY_PARAM:
            return handleSafeListeningParamsT2(data)
        case .SAFE_LISTENING_RET_EXTENDED_PARAM:
            return handleSafeListeningExtendedParamT2(data)
        default:
            return MDREvent.unhandled.rawValue
        }
    }

    // MARK: - T1 Handlers (minimal set for Iter 5)

    private func handleProtocolInfoT1(_ data: Data) -> Int {
        var reader = DataReader(Data(data))
        guard let res = try? ConnectRetProtocolInfo.deserialize(from: &reader) else {
            return MDREvent.unhandled.rawValue
        }
        protocolInfo = ProtocolStates(
            version: Int(res.protocolVersion.value),
            hasTable1: res.supportTable1Value == .ENABLE,
            hasTable2: res.supportTable2Value == .ENABLE
        )
        awake(.protocolInfo)
        return MDREvent.ok.rawValue
    }

    private func handleSupportFunctionT1(_ data: Data) -> Int {
        var reader = DataReader(Data(data))
        guard let res = try? ConnectRetSupportFunction.deserialize(from: &reader) else {
            return MDREvent.unhandled.rawValue
        }
        support.table1Functions = Array(repeating: false, count: 256)
        for entry in res.supportFunctions {
            support.table1Functions[Int(entry.rawFunction)] = true
        }
        awake(.supportFunction)
        return MDREvent.supportFunctions.rawValue
    }

    private func handleCapabilityInfoT1(_ data: Data) -> Int {
        var reader = DataReader(Data(data))
        guard let res = try? ConnectRetCapabilityInfo.deserialize(from: &reader) else {
            return MDREvent.unhandled.rawValue
        }
        uniqueId = res.uniqueID.value
        return MDREvent.ok.rawValue
    }

    private func handleDeviceInfoT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let infoType = DeviceInfoType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch infoType {
        case .MODEL_NAME:
            guard let res = try? ConnectRetDeviceInfoModelName.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            modelName = res.value.value
            return MDREvent.deviceInfo.rawValue
        case .FW_VERSION:
            guard let res = try? ConnectRetDeviceInfoFwVersion.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            fwVersion = res.value.value
            return MDREvent.deviceInfo.rawValue
        case .SERIES_AND_COLOR_INFO:
            guard let res = try? ConnectRetDeviceInfoSeriesAndColor.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            modelSeries = res.series
            modelColor = res.color
            return MDREvent.deviceInfo.rawValue
        default:
            return MDREvent.unhandled.rawValue
        }
    }

    private func handlePowerStatusT1(_ data: Data) -> Int {
        guard data.count >= 2 else { return MDREvent.unhandled.rawValue }
        let typeByte = data[data.startIndex + 1]
        guard let powerType = PowerInquiredType(rawValue: typeByte) else {
            return MDREvent.unhandled.rawValue
        }
        var reader = DataReader(Data(data))
        switch powerType {
        case .BATTERY:
            guard let res = try? PowerRetStatusBattery.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            batteryL = BatteryState(
                level: res.batteryStatus.batteryLevel,
                threshold: 0xFF,
                charging: res.batteryStatus.chargingStatus
            )
            return MDREvent.battery.rawValue
        case .LEFT_RIGHT_BATTERY:
            guard let res = try? PowerRetStatusLeftRightBattery.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            batteryL = BatteryState(
                level: res.batteryStatus.leftBatteryLevel,
                threshold: 0xFF,
                charging: res.batteryStatus.leftChargingStatus
            )
            batteryR = BatteryState(
                level: res.batteryStatus.rightBatteryLevel,
                threshold: 0xFF,
                charging: res.batteryStatus.rightChargingStatus
            )
            return MDREvent.battery.rawValue
        case .CRADLE_BATTERY:
            guard let res = try? PowerRetStatusCradleBattery.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            batteryCase = BatteryState(
                level: res.batteryStatus.batteryLevel,
                threshold: 0xFF,
                charging: res.batteryStatus.chargingStatus
            )
            return MDREvent.battery.rawValue
        case .BATTERY_WITH_THRESHOLD:
            guard let res = try? PowerRetStatusBatteryThreshold.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            batteryL = BatteryState(
                level: res.batteryStatus.batteryStatus.batteryLevel,
                threshold: res.batteryStatus.batteryThreshold,
                charging: res.batteryStatus.batteryStatus.chargingStatus
            )
            return MDREvent.battery.rawValue
        case .LR_BATTERY_WITH_THRESHOLD:
            guard let res = try? PowerRetStatusLeftRightBatteryThreshold.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            batteryL = BatteryState(
                level: res.batteryStatus.leftBatteryLevel,
                threshold: res.leftBatteryThreshold,
                charging: res.batteryStatus.leftChargingStatus
            )
            batteryR = BatteryState(
                level: res.batteryStatus.rightBatteryLevel,
                threshold: res.rightBatteryThreshold,
                charging: res.batteryStatus.rightChargingStatus
            )
            return MDREvent.battery.rawValue
        case .CRADLE_BATTERY_WITH_THRESHOLD:
            guard let res = try? PowerRetStatusCradleBatteryThreshold.deserialize(from: &reader) else {
                return MDREvent.unhandled.rawValue
            }
            batteryCase = BatteryState(
                level: res.batteryStatus.batteryStatus.batteryLevel,
                threshold: res.batteryStatus.batteryThreshold,
                charging: res.batteryStatus.batteryStatus.chargingStatus
            )
            return MDREvent.battery.rawValue
        default:
            return MDREvent.unhandled.rawValue
        }
    }

    // MARK: - T2 Handlers (minimal set for Iter 5)

    private func handleSupportFunctionT2(_ data: Data) -> Int {
        var reader = DataReader(Data(data))
        guard let res = try? T2ConnectRetSupportFunction.deserialize(from: &reader) else {
            return MDREvent.unhandled.rawValue
        }
        support.table2Functions = Array(repeating: false, count: 256)
        for entry in res.supportFunctions {
            support.table2Functions[Int(entry.rawFunction)] = true
        }
        awake(.supportFunction)
        return MDREvent.supportFunctions.rawValue
    }
}
