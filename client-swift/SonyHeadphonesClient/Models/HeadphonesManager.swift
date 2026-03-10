import Foundation
@preconcurrency import Combine
import CoreBluetooth
import MDRProtocol

@MainActor
final class HeadphonesManager: ObservableObject {
    // MARK: - Connection State
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Device List
    @Published var devices: [MDRBluetoothDevice] = []
    @Published var selectedDeviceIndex: Int = 0

    // MARK: - Read-only Device Info
    @Published var modelName: String = ""
    @Published var uniqueId: String = ""
    @Published var fwVersion: String = ""
    @Published var modelSeries: ModelSeriesType = .noSeries
    @Published var modelColor: ModelColor = .default
    @Published var audioCodec: AudioCodec = .unsettled
    @Published var upscalingType: UpscalingType = .dsee
    @Published var upscalingAvailable: Bool = false

    // MARK: - Battery
    @Published var batteryL: BatteryInfo = .init()
    @Published var batteryR: BatteryInfo = .init()
    @Published var batteryCase: BatteryInfo = .init()

    // MARK: - Playback Metadata
    @Published var playTrackTitle: String = ""
    @Published var playTrackAlbum: String = ""
    @Published var playTrackArtist: String = ""
    @Published var playPause: PlaybackStatus = .unsettled

    // MARK: - Support Functions

    func supports(_ f: SupportFunctionT1) -> Bool {
        guard let hp = headphones else { return false }
        return hp.support.table1Functions[Int(f.rawValue)]
    }
    func supports(_ f: SupportFunctionT2) -> Bool {
        guard let hp = headphones else { return false }
        return hp.support.table2Functions[Int(f.rawValue)]
    }

    func supportsTable1Raw(_ val: UInt8) -> Bool {
        guard let hp = headphones else { return false }
        return hp.support.table1Functions[Int(val)]
    }

    func supportsTable2Raw(_ val: UInt8) -> Bool {
        guard let hp = headphones else { return false }
        return hp.support.table2Functions[Int(val)]
    }

    // MARK: - NC/ASM
    @Published var ncAsmEnabled: Bool = false { didSet { if ncAsmEnabled != oldValue { headphones?.ncAsmEnabled.desired = ncAsmEnabled } } }
    @Published var ncAsmFocusOnVoice: Bool = false { didSet { if ncAsmFocusOnVoice != oldValue { headphones?.ncAsmFocusOnVoice.desired = ncAsmFocusOnVoice } } }
    @Published var ncAsmAmbientLevel: Int32 = 0 { didSet { if ncAsmAmbientLevel != oldValue { headphones?.ncAsmAmbientLevel.desired = Int(ncAsmAmbientLevel) } } }
    @Published var ncAsmButtonFunction: ButtonFunction = .noFunction { didSet { if ncAsmButtonFunction != oldValue, let v = MDRProtocol.Function(rawValue: ncAsmButtonFunction.rawValue) { headphones?.ncAsmButtonFunction.desired = v } } }
    @Published var ncAsmMode: NcAsmMode = .nc { didSet { if ncAsmMode != oldValue, let v = MDRProtocol.NcAsmMode(rawValue: ncAsmMode.rawValue) { headphones?.ncAsmMode.desired = v } } }
    @Published var ncAsmAutoAsmEnabled: Bool = false { didSet { if ncAsmAutoAsmEnabled != oldValue { headphones?.ncAsmAutoAsmEnabled.desired = ncAsmAutoAsmEnabled } } }
    @Published var ncAsmNoiseAdaptiveSensitivity: NoiseAdaptiveSensitivity = .standard { didSet { if ncAsmNoiseAdaptiveSensitivity != oldValue, let v = MDRProtocol.NoiseAdaptiveSensitivity(rawValue: ncAsmNoiseAdaptiveSensitivity.rawValue) { headphones?.ncAsmNoiseAdaptiveSensitivity.desired = v } } }

    // MARK: - Power
    @Published var powerAutoOff: AutoPowerOffElements = .powerOffDisable { didSet { if powerAutoOff != oldValue, let v = MDRProtocol.AutoPowerOffElements(rawValue: powerAutoOff.rawValue) { headphones?.powerAutoOff.desired = v } } }

    // MARK: - Playback Controls
    @Published var playVolume: Int32 = 0 { didSet { if playVolume != oldValue { headphones?.playVolume.desired = Int(playVolume) } } }

    // MARK: - General Settings (bools 1-4)
    @Published var gsParamBool1: Bool = false { didSet { if gsParamBool1 != oldValue { headphones?.gsParamBool1.desired = gsParamBool1 } } }
    @Published var gsParamBool2: Bool = false { didSet { if gsParamBool2 != oldValue { headphones?.gsParamBool2.desired = gsParamBool2 } } }
    @Published var gsParamBool3: Bool = false { didSet { if gsParamBool3 != oldValue { headphones?.gsParamBool3.desired = gsParamBool3 } } }
    @Published var gsParamBool4: Bool = false { didSet { if gsParamBool4 != oldValue { headphones?.gsParamBool4.desired = gsParamBool4 } } }

    @Published var gsCapability1: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")
    @Published var gsCapability2: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")
    @Published var gsCapability3: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")
    @Published var gsCapability4: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")

    // MARK: - Upscaling
    @Published var upscalingEnabled: Bool = false { didSet { if upscalingEnabled != oldValue { headphones?.upscalingEnabled.desired = upscalingEnabled } } }

    // MARK: - Auto Pause
    @Published var autoPauseEnabled: Bool = false { didSet { if autoPauseEnabled != oldValue { headphones?.autoPauseEnabled.desired = autoPauseEnabled } } }

    // MARK: - Touch Function
    @Published var touchFunctionLeft: TouchPreset = .noFunction { didSet { if touchFunctionLeft != oldValue, let v = MDRProtocol.Preset(rawValue: touchFunctionLeft.rawValue) { headphones?.touchFunctionLeft.desired = v } } }
    @Published var touchFunctionRight: TouchPreset = .noFunction { didSet { if touchFunctionRight != oldValue, let v = MDRProtocol.Preset(rawValue: touchFunctionRight.rawValue) { headphones?.touchFunctionRight.desired = v } } }

    // MARK: - Speak To Chat
    @Published var speakToChatEnabled: Bool = false { didSet { if speakToChatEnabled != oldValue { headphones?.speakToChatEnabled.desired = speakToChatEnabled } } }
    @Published var speakToChatDetectSensitivity: DetectSensitivity = .auto_ { didSet { if speakToChatDetectSensitivity != oldValue, let v = MDRProtocol.DetectSensitivity(rawValue: speakToChatDetectSensitivity.rawValue) { headphones?.speakToChatDetectSensitivity.desired = v } } }
    @Published var speakToModeOutTime: ModeOutTime = .mid { didSet { if speakToModeOutTime != oldValue, let v = MDRProtocol.ModeOutTime(rawValue: speakToModeOutTime.rawValue) { headphones?.speakToModeOutTime.desired = v } } }

    // MARK: - Head Gesture
    @Published var headGestureEnabled: Bool = false { didSet { if headGestureEnabled != oldValue { headphones?.headGestureEnabled.desired = headGestureEnabled } } }

    // MARK: - Equalizer
    @Published var eqAvailable: Bool = false
    @Published var eqPresetId: EqPresetId = .off { didSet { if eqPresetId != oldValue, let v = MDRProtocol.EqPresetId(rawValue: eqPresetId.rawValue) { headphones?.eqPresetId.desired = v } } }
    @Published var eqClearBass: Int32 = 0 { didSet { if eqClearBass != oldValue { headphones?.eqClearBass.desired = Int(eqClearBass) } } }
    @Published var eqBands: [Int32] = []

    // MARK: - Voice Guidance
    @Published var voiceGuidanceEnabled: Bool = false { didSet { if voiceGuidanceEnabled != oldValue { headphones?.voiceGuidanceEnabled.desired = voiceGuidanceEnabled } } }
    @Published var voiceGuidanceVolume: Int32 = 0 { didSet { if voiceGuidanceVolume != oldValue { headphones?.voiceGuidanceVolume.desired = Int(voiceGuidanceVolume) } } }

    // MARK: - Pairing
    @Published var pairingMode: Bool = false { didSet { if pairingMode != oldValue { headphones?.pairingMode.desired = pairingMode } } }

    // MARK: - Paired Devices
    @Published var pairedDevices: [PairedDevice] = []
    @Published var multipointDeviceMac: String = ""

    // MARK: - Bugcheck
    @Published var bugcheckMessage: String = ""

    // MARK: - IsReady (busy spinner)
    @Published var isReady: Bool = true

    // MARK: - Connection Error Messages
    @Published var connectionErrorMessage: String = ""
    @Published var headphonesErrorMessage: String = ""

    // MARK: - Remember Device
    @Published var showRememberDeviceAlert: Bool = false
    private var connectedDeviceMac: String = ""

    // MARK: - Private
    private let transport: MDRConnectionTransport
    private var headphones: MDRHeadphones?
    private var pollTimer: AnyCancellable?
    private var isPollingSuppressed = false
    private var lastSnapshotWrite: Date = .distantPast

    // MARK: - MediaRemote (system Now Playing)
    private var mrTitle: String = ""
    private var mrArtist: String = ""
    private var mrAlbum: String = ""
    private var mrIsPlaying: Bool = false
    private var lastMediaRemoteQuery: Date = .distantPast

    private static let mrBundle: CFBundle? = CFBundleCreate(kCFAllocatorDefault,
        NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

    private typealias MRGetInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRGetClientFn = @convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void

    private static let mrGetInfo: MRGetInfoFn? = {
        guard let b = mrBundle, let p = CFBundleGetFunctionPointerForName(b, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return nil }
        return unsafeBitCast(p, to: MRGetInfoFn.self)
    }()

    private static let mrGetClient: MRGetClientFn? = {
        guard let b = mrBundle, let p = CFBundleGetFunctionPointerForName(b, "MRMediaRemoteGetNowPlayingClient" as CFString) else { return nil }
        return unsafeBitCast(p, to: MRGetClientFn.self)
    }()

    // Reconnect
    private var reconnectTimer: AnyCancellable?
    private(set) var reconnectStateMachine = ReconnectStateMachine()
    private var isManualDisconnect: Bool = false

    // Triggers macOS Bluetooth permission dialog on first launch
    private var centralManager: CBCentralManager?

    // MARK: - Lifecycle
    init(transport: MDRConnectionTransport = BluetoothTransport()) {
        self.transport = transport
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        connectionState = .discovering
        refreshDevices()
        autoConnectIfRemembered()
    }

    deinit {
        pollTimer?.cancel()
        reconnectTimer?.cancel()
        transport.disconnect()
    }

    // MARK: - Device Discovery
    func refreshDevices() {
        devices = transport.pairedDevices()

        // Default select first Sony device
        selectedDeviceIndex = 0
        for (i, device) in devices.enumerated() {
            if Self.isSonyDevice(device.name) {
                selectedDeviceIndex = i
                break
            }
        }
    }

    static func isSonyDevice(_ name: String) -> Bool {
        let prefixes = ["WH-", "WF-", "WI-", "MDR-", "LinkBuds", "ULT WEAR", "INZONE"]
        return prefixes.contains { name.localizedCaseInsensitiveContains($0) && name.hasPrefix($0) == false ? name.lowercased().hasPrefix($0.lowercased()) : name.hasPrefix($0) }
    }

    static func isSonyDeviceSimple(_ name: String) -> Bool {
        let prefixes = ["WH-", "WF-", "WI-", "MDR-", "LinkBuds", "ULT WEAR", "INZONE"]
        let lower = name.lowercased()
        return prefixes.contains { lower.hasPrefix($0.lowercased()) }
    }

    func deviceName(at index: Int) -> String {
        guard index >= 0 && index < devices.count else { return "" }
        return devices[index].name
    }

    func deviceMac(at index: Int) -> String {
        guard index >= 0 && index < devices.count else { return "" }
        return devices[index].macAddress
    }

    // MARK: - Connect / Disconnect
    func connect(deviceIndex: Int) {
        let mac = deviceMac(at: deviceIndex)
        connectedDeviceMac = mac
        transport.connect(macAddress: mac)
        if case .error(let msg) = transport.connectionState {
            connectionState = .error("Connection failed: \(msg)")
            return
        }
        connectionState = .connecting
        startPollTimer()
    }

    var rememberedDeviceMac: String? {
        UserDefaults.standard.string(forKey: "rememberedDeviceMac")
    }

    var rememberedDeviceName: String? {
        UserDefaults.standard.string(forKey: "rememberedDeviceName")
    }

    func rememberCurrentDevice() {
        UserDefaults.standard.set(connectedDeviceMac, forKey: "rememberedDeviceMac")
        UserDefaults.standard.set(modelName, forKey: "rememberedDeviceName")
    }

    func forgetRememberedDevice() {
        UserDefaults.standard.removeObject(forKey: "rememberedDeviceMac")
        UserDefaults.standard.removeObject(forKey: "rememberedDeviceName")
    }

    private func autoConnectIfRemembered() {
        guard let savedMac = rememberedDeviceMac, !savedMac.isEmpty else { return }
        for (i, _) in devices.enumerated() {
            if deviceMac(at: i) == savedMac {
                selectedDeviceIndex = i
                connect(deviceIndex: i)
                return
            }
        }
    }

    func disconnect() {
        isManualDisconnect = true
        performFullCleanup()
        connectionState = .discovering
        refreshDevices()
    }

    func cancelReconnect() {
        performFullCleanup()
        let action = reconnectStateMachine.cancel()
        applyAction(action)
    }

    func shutdown() {
        headphones?.shutdown.desired = true
    }

    // MARK: - Playback Controls
    func sendPlaybackControl(_ control: PlaybackControl) {
        guard let v = MDRProtocol.PlaybackControl(rawValue: control.rawValue) else { return }
        headphones?.playControl.desired = v
    }

    // MARK: - EQ Band Write
    func setEqBandValue(index: Int, value: Int32) {
        guard let hp = headphones, index >= 0, index < eqBands.count else { return }
        eqBands[index] = value
        var config = hp.eqConfig.desired
        if index < config.count {
            config[index] = Int(value)
            hp.eqConfig.desired = config
        }
    }

    // MARK: - Device Management
    func setMultipointDeviceMac(_ mac: String) {
        headphones?.multipointDeviceMac.desired = mac
    }

    func disconnectPairedDevice(_ mac: String) {
        headphones?.pairedDeviceDisconnectMac.desired = mac
    }

    func connectPairedDevice(_ mac: String) {
        headphones?.pairedDeviceConnectMac.desired = mac
    }

    func unpairDevice(_ mac: String) {
        headphones?.pairedDeviceUnpairMac.desired = mac
    }

    // MARK: - Poll Timer
    private func startPollTimer() {
        pollTimer?.cancel()
        pollTimer = Timer.publish(every: 1.0/60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pollTick()
            }
    }

    private func pollTick() {
        guard !isPollingSuppressed else { return }

        switch connectionState {
        case .connecting:
            pollConnecting()
        case .connected:
            pollConnected()
        default:
            break
        }
    }

    private func pollConnecting() {
        let state = transport.poll(timeoutMS: 0)
        switch state {
        case .connected:
            let hp = MDRHeadphones(transport: transport)
            headphones = hp
            hp.requestInitV2()
            connectionState = .connected
            let _ = reconnectStateMachine.handleConnected()
            isManualDisconnect = false
            if rememberedDeviceMac != connectedDeviceMac {
                showRememberDeviceAlert = true
            }

        case .connecting:
            connectionErrorMessage = transport.lastError

        case .error(let msg):
            connectionErrorMessage = msg
            transport.disconnect()
            if reconnectStateMachine.isActive {
                applyAction(reconnectStateMachine.handleConnectFailed())
            } else {
                handleUnexpectedDisconnect(error: connectionErrorMessage)
            }

        case .disconnected:
            connectionErrorMessage = transport.lastError
            transport.disconnect()
            if reconnectStateMachine.isActive {
                applyAction(reconnectStateMachine.handleConnectFailed())
            } else {
                let errorMsg = connectionErrorMessage.isEmpty ? "Disconnected" : connectionErrorMessage
                handleUnexpectedDisconnect(error: errorMsg)
            }
        }
    }

    private func pollConnected() {
        guard let hp = headphones else { return }

        // Tick runloop so IOBluetooth delegate callbacks (e.g. rfcommChannelClosed) fire
        transport.poll(timeoutMS: 0)

        let event = hp.pollEvents()

        if let mdrEvent = MDREvent(rawValue: event) {
            switch mdrEvent {
            case .taskInitOK:
                hp.requestSyncV2()
            case .idle:
                if hp.isDirty {
                    hp.requestCommitV2()
                }
            case .error:
                headphonesErrorMessage = hp.lastError
                handleUnexpectedDisconnect(error: "Disconnected: \(headphonesErrorMessage)")
                return
            default:
                break
            }
        }

        queryMediaRemote()
        readAllFields()
    }

    private func queryMediaRemote() {
        let now = Date()
        guard now.timeIntervalSince(lastMediaRemoteQuery) >= 2.0 else { return }
        lastMediaRemoteQuery = now

        Self.mrGetInfo?(DispatchQueue.main) { [weak self] info in
            guard let self else { return }
            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
            let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
            self.mrTitle = title
            self.mrArtist = artist
            self.mrAlbum = album
            self.mrIsPlaying = rate > 0
        }
    }

    // MARK: - Cleanup & Reconnect

    private func performFullCleanup() {
        pollTimer?.cancel()
        pollTimer = nil
        reconnectTimer?.cancel()
        reconnectTimer = nil
        headphones = nil
        transport.disconnect()

        batteryL = .init()
        batteryR = .init()
        batteryCase = .init()

        playTrackTitle = ""
        playTrackAlbum = ""
        playTrackArtist = ""
        playPause = .unsettled

        writeDisconnectedSnapshot()
    }

    private func handleUnexpectedDisconnect(error: String) {
        let deviceMac = connectedDeviceMac
        let deviceName = modelName.isEmpty ? (rememberedDeviceName ?? "") : modelName

        performFullCleanup()

        if isManualDisconnect {
            isManualDisconnect = false
            connectionState = .error(error)
            return
        }

        if ReconnectStateMachine.shouldReconnect(deviceMac: deviceMac, isManualDisconnect: false) {
            let action = reconnectStateMachine.handleDisconnect(deviceMac: deviceMac, deviceName: deviceName)
            applyAction(action)
        } else {
            connectionState = .error(error)
        }
    }

    private func applyAction(_ action: ReconnectAction) {
        switch action {
        case .none:
            break

        case .scheduleRetry(let delay, let attempt, let maxAttempts):
            connectionState = .reconnecting(
                attempt: attempt,
                maxAttempts: maxAttempts,
                deviceName: reconnectStateMachine.deviceName
            )
            reconnectTimer?.cancel()
            reconnectTimer = Timer.publish(every: delay, on: .main, in: .common)
                .autoconnect()
                .first()
                .sink { [weak self] _ in
                    guard let self else { return }
                    let action = self.reconnectStateMachine.timerFired()
                    self.applyAction(action)
                }

        case .attemptConnect(let mac):
            reconnectTimer?.cancel()
            reconnectTimer = nil
            refreshDevices()

            var deviceIndex: Int?
            for (i, _) in devices.enumerated() {
                if deviceMac(at: i) == mac {
                    deviceIndex = i
                    break
                }
            }

            guard let idx = deviceIndex else {
                applyAction(reconnectStateMachine.handleDeviceNotFound())
                return
            }

            selectedDeviceIndex = idx
            connectedDeviceMac = mac
            transport.connect(macAddress: mac)

            if case .error(_) = transport.connectionState {
                transport.disconnect()
                applyAction(reconnectStateMachine.handleConnectFailed())
                return
            }

            connectionState = .connecting
            startPollTimer()

        case .giveUp(let error):
            connectionState = .error(error)

        case .resetToDiscovery:
            connectionState = .discovering
            refreshDevices()
        }
    }

    private func writeDisconnectedSnapshot() {
        let snapshot = HeadphonesSnapshot.disconnected()
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults(suiteName: HeadphonesSnapshot.suiteName)?.set(data, forKey: HeadphonesSnapshot.key)
        }
    }

    // MARK: - Read all fields from MDRHeadphones
    private func readAllFields() {
        guard let hp = headphones else { return }

        let newModelName = hp.modelName
        if modelName != newModelName { modelName = newModelName }

        let newUniqueId = hp.uniqueId
        if uniqueId != newUniqueId { uniqueId = newUniqueId }

        let newFWVersion = hp.fwVersion
        if fwVersion != newFWVersion { fwVersion = newFWVersion }

        let newSeries = ModelSeriesType(rawValue: hp.modelSeries.rawValue) ?? .noSeries
        if modelSeries != newSeries { modelSeries = newSeries }

        let newColor = ModelColor(rawValue: hp.modelColor.rawValue) ?? .default
        if modelColor != newColor { modelColor = newColor }

        let newCodec = AudioCodec(rawValue: hp.audioCodec.rawValue) ?? .other
        if audioCodec != newCodec { audioCodec = newCodec }

        let newUpType = UpscalingType(rawValue: hp.upscalingType.rawValue) ?? .dsee
        if upscalingType != newUpType { upscalingType = newUpType }

        let newUpAvail = hp.upscalingAvailable
        if upscalingAvailable != newUpAvail { upscalingAvailable = newUpAvail }

        // Battery
        let newBattL = BatteryInfo(level: hp.batteryL.level, threshold: hp.batteryL.threshold, charging: BatteryChargingStatus(rawValue: hp.batteryL.charging.rawValue) ?? .notCharging)
        if batteryL != newBattL { batteryL = newBattL }

        let newBattR = BatteryInfo(level: hp.batteryR.level, threshold: hp.batteryR.threshold, charging: BatteryChargingStatus(rawValue: hp.batteryR.charging.rawValue) ?? .notCharging)
        if batteryR != newBattR { batteryR = newBattR }

        let newBattCase = BatteryInfo(level: hp.batteryCase.level, threshold: hp.batteryCase.threshold, charging: BatteryChargingStatus(rawValue: hp.batteryCase.charging.rawValue) ?? .notCharging)
        if batteryCase != newBattCase { batteryCase = newBattCase }

        // Playback metadata — prefer MediaRemote when actively playing (AVRCP can be stale)
        let useMediaRemote = mrIsPlaying && !mrTitle.isEmpty
        let newTitle = useMediaRemote ? mrTitle : hp.playTrackTitle
        if playTrackTitle != newTitle { playTrackTitle = newTitle }
        let newArtist = useMediaRemote ? mrArtist : hp.playTrackArtist
        if playTrackArtist != newArtist { playTrackArtist = newArtist }
        let newAlbum = useMediaRemote ? mrAlbum : hp.playTrackAlbum
        if playTrackAlbum != newAlbum { playTrackAlbum = newAlbum }
        let newPlayPause = PlaybackStatus(rawValue: hp.playPause.rawValue) ?? .unsettled
        if playPause != newPlayPause { playPause = newPlayPause }

        // NC/ASM - read current values (don't write back unless user changes)
        isPollingSuppressed = true
        defer { isPollingSuppressed = false }

        let newNcEnabled = hp.ncAsmEnabled.desired
        if ncAsmEnabled != newNcEnabled { ncAsmEnabled = newNcEnabled }
        let newNcFocus = hp.ncAsmFocusOnVoice.desired
        if ncAsmFocusOnVoice != newNcFocus { ncAsmFocusOnVoice = newNcFocus }
        let newAmbient = Int32(hp.ncAsmAmbientLevel.desired)
        if ncAsmAmbientLevel != newAmbient { ncAsmAmbientLevel = newAmbient }
        let newBtnFunc = ButtonFunction(rawValue: hp.ncAsmButtonFunction.desired.rawValue) ?? .noFunction
        if ncAsmButtonFunction != newBtnFunc { ncAsmButtonFunction = newBtnFunc }
        let newMode = NcAsmMode(rawValue: hp.ncAsmMode.desired.rawValue) ?? .nc
        if ncAsmMode != newMode { ncAsmMode = newMode }
        let newAutoAsm = hp.ncAsmAutoAsmEnabled.desired
        if ncAsmAutoAsmEnabled != newAutoAsm { ncAsmAutoAsmEnabled = newAutoAsm }
        let newAdaptSens = NoiseAdaptiveSensitivity(rawValue: hp.ncAsmNoiseAdaptiveSensitivity.desired.rawValue) ?? .standard
        if ncAsmNoiseAdaptiveSensitivity != newAdaptSens { ncAsmNoiseAdaptiveSensitivity = newAdaptSens }

        // Power
        let newPowerAutoOff = AutoPowerOffElements(rawValue: hp.powerAutoOff.desired.rawValue) ?? .powerOffDisable
        if powerAutoOff != newPowerAutoOff { powerAutoOff = newPowerAutoOff }

        // Volume
        let newVol = Int32(hp.playVolume.desired)
        if playVolume != newVol { playVolume = newVol }

        // GS Params
        let newGS1 = hp.gsParamBool1.desired
        if gsParamBool1 != newGS1 { gsParamBool1 = newGS1 }
        let newGS2 = hp.gsParamBool2.desired
        if gsParamBool2 != newGS2 { gsParamBool2 = newGS2 }
        let newGS3 = hp.gsParamBool3.desired
        if gsParamBool3 != newGS3 { gsParamBool3 = newGS3 }
        let newGS4 = hp.gsParamBool4.desired
        if gsParamBool4 != newGS4 { gsParamBool4 = newGS4 }

        // GS Capabilities
        let caps = [hp.gsCapability1, hp.gsCapability2, hp.gsCapability3, hp.gsCapability4]
        for (i, protoCap) in caps.enumerated() {
            let cap = GeneralSettingCapability(
                type: protoCap.type.rawValue,
                subject: protoCap.value.subject.value,
                summary: protoCap.value.summary.value
            )
            switch i {
            case 0: if gsCapability1 != cap { gsCapability1 = cap }
            case 1: if gsCapability2 != cap { gsCapability2 = cap }
            case 2: if gsCapability3 != cap { gsCapability3 = cap }
            case 3: if gsCapability4 != cap { gsCapability4 = cap }
            default: break
            }
        }

        // Upscaling
        let newUpEnabled = hp.upscalingEnabled.desired
        if upscalingEnabled != newUpEnabled { upscalingEnabled = newUpEnabled }

        // Auto Pause
        let newAutoPause = hp.autoPauseEnabled.desired
        if autoPauseEnabled != newAutoPause { autoPauseEnabled = newAutoPause }

        // Touch
        let newTouchL = TouchPreset(rawValue: hp.touchFunctionLeft.desired.rawValue) ?? .noFunction
        if touchFunctionLeft != newTouchL { touchFunctionLeft = newTouchL }
        let newTouchR = TouchPreset(rawValue: hp.touchFunctionRight.desired.rawValue) ?? .noFunction
        if touchFunctionRight != newTouchR { touchFunctionRight = newTouchR }

        // Speak To Chat
        let newSTC = hp.speakToChatEnabled.desired
        if speakToChatEnabled != newSTC { speakToChatEnabled = newSTC }
        let newSTCSens = DetectSensitivity(rawValue: hp.speakToChatDetectSensitivity.desired.rawValue) ?? .auto_
        if speakToChatDetectSensitivity != newSTCSens { speakToChatDetectSensitivity = newSTCSens }
        let newSTCTime = ModeOutTime(rawValue: hp.speakToModeOutTime.desired.rawValue) ?? .mid
        if speakToModeOutTime != newSTCTime { speakToModeOutTime = newSTCTime }

        // Head Gesture
        let newHeadGesture = hp.headGestureEnabled.desired
        if headGestureEnabled != newHeadGesture { headGestureEnabled = newHeadGesture }

        // EQ
        let newEqAvail = hp.eqAvailable.current
        if eqAvailable != newEqAvail { eqAvailable = newEqAvail }
        let newEqPreset = EqPresetId(rawValue: hp.eqPresetId.desired.rawValue) ?? .off
        if eqPresetId != newEqPreset { eqPresetId = newEqPreset }
        let newClearBass = Int32(hp.eqClearBass.desired)
        if eqClearBass != newClearBass { eqClearBass = newClearBass }

        let config = hp.eqConfig.desired
        let bandCount = config.count
        if eqBands.count != bandCount {
            eqBands = config.map { Int32($0) }
        } else {
            for i in 0..<bandCount {
                let val = Int32(config[i])
                if eqBands[i] != val { eqBands[i] = val }
            }
        }

        // Voice Guidance
        let newVGEnabled = hp.voiceGuidanceEnabled.desired
        if voiceGuidanceEnabled != newVGEnabled { voiceGuidanceEnabled = newVGEnabled }
        let newVGVol = Int32(hp.voiceGuidanceVolume.desired)
        if voiceGuidanceVolume != newVGVol { voiceGuidanceVolume = newVGVol }

        // Pairing
        let newPairing = hp.pairingMode.desired
        if pairingMode != newPairing { pairingMode = newPairing }

        // Multipoint Mac
        let newMPMac = hp.multipointDeviceMac.desired
        if multipointDeviceMac != newMPMac { multipointDeviceMac = newMPMac }

        // Paired Devices
        var newPaired: [PairedDevice] = []
        for dev in hp.pairedDevices {
            newPaired.append(PairedDevice(id: dev.macAddress, name: dev.name, connected: dev.connected))
        }
        if pairedDevices != newPaired { pairedDevices = newPaired }

        // IsReady
        let newReady = hp.isReady
        if isReady != newReady { isReady = newReady }

        writeSharedStateIfNeeded()
    }

    // MARK: - Shared State for Widget

    private func writeSharedStateIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastSnapshotWrite) >= 5 else { return }
        lastSnapshotWrite = now

        let ncMode: String = {
            if !ncAsmEnabled { return "off" }
            return ncAsmMode == .nc ? "nc" : "ambient"
        }()

        let snapshot = HeadphonesSnapshot(
            isConnected: connectionState == .connected,
            modelName: modelName,
            batteryL: Int(batteryL.level),
            batteryR: Int(batteryR.level),
            batteryCase: Int(batteryCase.level),
            batteryLCharging: batteryL.charging != .notCharging,
            batteryRCharging: batteryR.charging != .notCharging,
            batteryCaseCharging: batteryCase.charging != .notCharging,
            ncMode: ncMode,
            audioCodec: audioCodec.displayName,
            trackTitle: playTrackTitle,
            trackArtist: playTrackArtist,
            isPlaying: playPause == .play,
            lastUpdated: now
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults(suiteName: HeadphonesSnapshot.suiteName)?.set(data, forKey: HeadphonesSnapshot.key)
        }
    }
}
