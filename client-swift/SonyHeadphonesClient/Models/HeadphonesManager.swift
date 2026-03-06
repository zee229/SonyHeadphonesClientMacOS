import Foundation
import Combine

@MainActor
final class HeadphonesManager: ObservableObject {
    // MARK: - Connection State
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Device List
    @Published var devices: [MDRDeviceInfo] = []
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
    var supportTable1: [UInt8: Bool] = [:]
    var supportTable2: [UInt8: Bool] = [:]

    func supports(_ f: SupportFunctionT1) -> Bool {
        guard let hp = headphones else { return false }
        return mdrHeadphonesSupportTable1(hp, f.rawValue) != 0
    }
    func supports(_ f: SupportFunctionT2) -> Bool {
        guard let hp = headphones else { return false }
        return mdrHeadphonesSupportTable2(hp, f.rawValue) != 0
    }

    func supportsTable1Raw(_ val: UInt8) -> Bool {
        guard let hp = headphones else { return false }
        return mdrHeadphonesSupportTable1(hp, val) != 0
    }

    func supportsTable2Raw(_ val: UInt8) -> Bool {
        guard let hp = headphones else { return false }
        return mdrHeadphonesSupportTable2(hp, val) != 0
    }

    // MARK: - NC/ASM
    @Published var ncAsmEnabled: Bool = false { didSet { if ncAsmEnabled != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmEnabledDesired(hp, ncAsmEnabled ? 1 : 0) } } }
    @Published var ncAsmFocusOnVoice: Bool = false { didSet { if ncAsmFocusOnVoice != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmFocusOnVoiceDesired(hp, ncAsmFocusOnVoice ? 1 : 0) } } }
    @Published var ncAsmAmbientLevel: Int32 = 0 { didSet { if ncAsmAmbientLevel != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmAmbientLevelDesired(hp, ncAsmAmbientLevel) } } }
    @Published var ncAsmButtonFunction: ButtonFunction = .noFunction { didSet { if ncAsmButtonFunction != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmButtonFunctionDesired(hp, ncAsmButtonFunction.rawValue) } } }
    @Published var ncAsmMode: NcAsmMode = .nc { didSet { if ncAsmMode != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmModeDesired(hp, ncAsmMode.rawValue) } } }
    @Published var ncAsmAutoAsmEnabled: Bool = false { didSet { if ncAsmAutoAsmEnabled != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmAutoAsmEnabledDesired(hp, ncAsmAutoAsmEnabled ? 1 : 0) } } }
    @Published var ncAsmNoiseAdaptiveSensitivity: NoiseAdaptiveSensitivity = .standard { didSet { if ncAsmNoiseAdaptiveSensitivity != oldValue, let hp = headphones { mdrHeadphonesSetNcAsmNoiseAdaptiveSensitivityDesired(hp, ncAsmNoiseAdaptiveSensitivity.rawValue) } } }

    // MARK: - Power
    @Published var powerAutoOff: AutoPowerOffElements = .powerOffDisable { didSet { if powerAutoOff != oldValue, let hp = headphones { mdrHeadphonesSetPowerAutoOffDesired(hp, powerAutoOff.rawValue) } } }

    // MARK: - Playback Controls
    @Published var playVolume: Int32 = 0 { didSet { if playVolume != oldValue, let hp = headphones { mdrHeadphonesSetPlayVolumeDesired(hp, playVolume) } } }

    // MARK: - General Settings (bools 1-4)
    @Published var gsParamBool1: Bool = false { didSet { if gsParamBool1 != oldValue, let hp = headphones { mdrHeadphonesSetGsParamBoolDesired(hp, 1, gsParamBool1 ? 1 : 0) } } }
    @Published var gsParamBool2: Bool = false { didSet { if gsParamBool2 != oldValue, let hp = headphones { mdrHeadphonesSetGsParamBoolDesired(hp, 2, gsParamBool2 ? 1 : 0) } } }
    @Published var gsParamBool3: Bool = false { didSet { if gsParamBool3 != oldValue, let hp = headphones { mdrHeadphonesSetGsParamBoolDesired(hp, 3, gsParamBool3 ? 1 : 0) } } }
    @Published var gsParamBool4: Bool = false { didSet { if gsParamBool4 != oldValue, let hp = headphones { mdrHeadphonesSetGsParamBoolDesired(hp, 4, gsParamBool4 ? 1 : 0) } } }

    @Published var gsCapability1: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")
    @Published var gsCapability2: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")
    @Published var gsCapability3: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")
    @Published var gsCapability4: GeneralSettingCapability = .init(type: 0, subject: "", summary: "")

    // MARK: - Upscaling
    @Published var upscalingEnabled: Bool = false { didSet { if upscalingEnabled != oldValue, let hp = headphones { mdrHeadphonesSetUpscalingEnabledDesired(hp, upscalingEnabled ? 1 : 0) } } }

    // MARK: - Auto Pause
    @Published var autoPauseEnabled: Bool = false { didSet { if autoPauseEnabled != oldValue, let hp = headphones { mdrHeadphonesSetAutoPauseEnabledDesired(hp, autoPauseEnabled ? 1 : 0) } } }

    // MARK: - Touch Function
    @Published var touchFunctionLeft: TouchPreset = .noFunction { didSet { if touchFunctionLeft != oldValue, let hp = headphones { mdrHeadphonesSetTouchFunctionLeftDesired(hp, touchFunctionLeft.rawValue) } } }
    @Published var touchFunctionRight: TouchPreset = .noFunction { didSet { if touchFunctionRight != oldValue, let hp = headphones { mdrHeadphonesSetTouchFunctionRightDesired(hp, touchFunctionRight.rawValue) } } }

    // MARK: - Speak To Chat
    @Published var speakToChatEnabled: Bool = false { didSet { if speakToChatEnabled != oldValue, let hp = headphones { mdrHeadphonesSetSpeakToChatEnabledDesired(hp, speakToChatEnabled ? 1 : 0) } } }
    @Published var speakToChatDetectSensitivity: DetectSensitivity = .auto_ { didSet { if speakToChatDetectSensitivity != oldValue, let hp = headphones { mdrHeadphonesSetSpeakToChatDetectSensitivityDesired(hp, speakToChatDetectSensitivity.rawValue) } } }
    @Published var speakToModeOutTime: ModeOutTime = .mid { didSet { if speakToModeOutTime != oldValue, let hp = headphones { mdrHeadphonesSetSpeakToModeOutTimeDesired(hp, speakToModeOutTime.rawValue) } } }

    // MARK: - Head Gesture
    @Published var headGestureEnabled: Bool = false { didSet { if headGestureEnabled != oldValue, let hp = headphones { mdrHeadphonesSetHeadGestureEnabledDesired(hp, headGestureEnabled ? 1 : 0) } } }

    // MARK: - Equalizer
    @Published var eqAvailable: Bool = false
    @Published var eqPresetId: EqPresetId = .off { didSet { if eqPresetId != oldValue, let hp = headphones { mdrHeadphonesSetEqPresetIdDesired(hp, eqPresetId.rawValue) } } }
    @Published var eqClearBass: Int32 = 0 { didSet { if eqClearBass != oldValue, let hp = headphones { mdrHeadphonesSetEqClearBassDesired(hp, eqClearBass) } } }
    @Published var eqBands: [Int32] = []

    // MARK: - Voice Guidance
    @Published var voiceGuidanceEnabled: Bool = false { didSet { if voiceGuidanceEnabled != oldValue, let hp = headphones { mdrHeadphonesSetVoiceGuidanceEnabledDesired(hp, voiceGuidanceEnabled ? 1 : 0) } } }
    @Published var voiceGuidanceVolume: Int32 = 0 { didSet { if voiceGuidanceVolume != oldValue, let hp = headphones { mdrHeadphonesSetVoiceGuidanceVolumeDesired(hp, voiceGuidanceVolume) } } }

    // MARK: - Pairing
    @Published var pairingMode: Bool = false { didSet { if pairingMode != oldValue, let hp = headphones { mdrHeadphonesSetPairingModeDesired(hp, pairingMode ? 1 : 0) } } }

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

    // MARK: - Private
    private var macOSConnection: OpaquePointer? // MDRConnectionMacOS*
    private var connection: UnsafeMutablePointer<MDRConnection>? // MDRConnection*
    private var headphones: OpaquePointer? // MDRHeadphones*
    private var pollTimer: AnyCancellable?
    private var isPollingSuppressed = false

    // MARK: - Lifecycle
    init() {
        macOSConnection = mdrConnectionMacOSCreate()
        connection = mdrConnectionMacOSGet(macOSConnection)
        connectionState = .discovering
        refreshDevices()
    }

    deinit {
        pollTimer?.cancel()
        if let hp = headphones { mdrHeadphonesDestroy(hp) }
        if let conn = macOSConnection { mdrConnectionMacOSDestroy(conn) }
    }

    // MARK: - Device Discovery
    func refreshDevices() {
        guard let conn = connection else { return }
        var pList: UnsafeMutablePointer<MDRDeviceInfo>?
        var count: Int32 = 0
        let r = mdrConnectionGetDevicesList(conn, &pList, &count)
        guard r == MDR_RESULT_OK, let list = pList else { return }
        var result: [MDRDeviceInfo] = []
        for i in 0..<Int(count) {
            result.append(list[i])
        }
        devices = result
        mdrConnectionFreeDevicesList(conn, &pList)

        // Default select first Sony device
        selectedDeviceIndex = 0
        for (i, device) in devices.enumerated() {
            let name = withUnsafePointer(to: device.szDeviceName) {
                $0.withMemoryRebound(to: CChar.self, capacity: 128) { String(cString: $0) }
            }
            if Self.isSonyDevice(name) {
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
        return withUnsafePointer(to: devices[index].szDeviceName) {
            $0.withMemoryRebound(to: CChar.self, capacity: 128) { String(cString: $0) }
        }
    }

    func deviceMac(at index: Int) -> String {
        guard index >= 0 && index < devices.count else { return "" }
        return withUnsafePointer(to: devices[index].szDeviceMacAddress) {
            $0.withMemoryRebound(to: CChar.self, capacity: 18) { String(cString: $0) }
        }
    }

    // MARK: - Connect / Disconnect
    func connect(deviceIndex: Int) {
        guard let conn = connection else { return }
        let mac = deviceMac(at: deviceIndex)
        let uuid = MDR_SERVICE_UUID_XM5
        let r = mdrConnectionConnect(conn, mac, uuid)
        if r != MDR_RESULT_OK && r != MDR_RESULT_INPROGRESS {
            connectionState = .error("Connection failed: \(String(cString: mdrConnectionGetLastError(conn)))")
            return
        }
        connectionState = .connecting
        startPollTimer()
    }

    func disconnect() {
        pollTimer?.cancel()
        pollTimer = nil
        if let hp = headphones {
            mdrHeadphonesDestroy(hp)
            headphones = nil
        }
        if let conn = connection {
            mdrConnectionDisconnect(conn)
        }
        connectionState = .discovering
        refreshDevices()
    }

    func shutdown() {
        guard let hp = headphones else { return }
        mdrHeadphonesSetShutdownDesired(hp, 1)
    }

    // MARK: - Playback Controls
    func sendPlaybackControl(_ control: PlaybackControl) {
        guard let hp = headphones else { return }
        mdrHeadphonesSetPlayControlDesired(hp, control.rawValue)
    }

    // MARK: - EQ Band Write
    func setEqBandValue(index: Int, value: Int32) {
        guard let hp = headphones, index >= 0, index < eqBands.count else { return }
        eqBands[index] = value
        mdrHeadphonesSetEqBandValueDesired(hp, Int32(index), value)
    }

    // MARK: - Device Management
    func setMultipointDeviceMac(_ mac: String) {
        guard let hp = headphones else { return }
        multipointDeviceMac = mac
        mdrHeadphonesSetMultipointDeviceMacDesired(hp, mac)
    }

    func disconnectPairedDevice(_ mac: String) {
        guard let hp = headphones else { return }
        mdrHeadphonesSetPairedDeviceDisconnectMacDesired(hp, mac)
    }

    func connectPairedDevice(_ mac: String) {
        guard let hp = headphones else { return }
        mdrHeadphonesSetPairedDeviceConnectMacDesired(hp, mac)
    }

    func unpairDevice(_ mac: String) {
        guard let hp = headphones else { return }
        mdrHeadphonesSetPairedDeviceUnpairMacDesired(hp, mac)
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
        guard let conn = connection else { return }
        let r = mdrConnectionPoll(conn, 0)
        switch r {
        case MDR_RESULT_OK:
            // Connected! Create headphones
            headphones = mdrHeadphonesCreate(conn)
            guard let hp = headphones else {
                connectionState = .error("Failed to create headphones")
                return
            }
            let initResult = mdrHeadphonesRequestInitV2(hp)
            guard initResult == MDR_RESULT_OK else {
                connectionState = .error("Init failed")
                return
            }
            connectionState = .connected

        case MDR_RESULT_ERROR_TIMEOUT, MDR_RESULT_INPROGRESS:
            // Still connecting
            connectionErrorMessage = String(cString: mdrConnectionGetLastError(conn))

        default:
            // Error
            connectionErrorMessage = String(cString: mdrConnectionGetLastError(conn))
            mdrConnectionDisconnect(conn)
            connectionState = .error(connectionErrorMessage)
        }
    }

    private func pollConnected() {
        guard let hp = headphones, let conn = connection else { return }

        let event = mdrHeadphonesPollEvents(hp)

        switch event {
        case MDR_HEADPHONES_TASK_INIT_OK:
            let _ = mdrHeadphonesRequestSyncV2(hp)
        case MDR_HEADPHONES_IDLE:
            if mdrHeadphonesIsDirty(hp) == MDR_RESULT_INPROGRESS {
                let _ = mdrHeadphonesRequestCommitV2(hp)
            }
        case MDR_HEADPHONES_ERROR:
            connectionErrorMessage = String(cString: mdrConnectionGetLastError(conn))
            headphonesErrorMessage = String(cString: mdrHeadphonesGetLastError(hp))
            mdrConnectionDisconnect(conn)
            connectionState = .error("Disconnected: \(headphonesErrorMessage)")
            return
        default:
            break
        }

        readAllFields()
    }

    // MARK: - Read all fields from C
    private func readAllFields() {
        guard let hp = headphones else { return }

        let newModelName = String(cString: mdrHeadphonesGetModelName(hp))
        if modelName != newModelName { modelName = newModelName }

        let newUniqueId = String(cString: mdrHeadphonesGetUniqueId(hp))
        if uniqueId != newUniqueId { uniqueId = newUniqueId }

        let newFWVersion = String(cString: mdrHeadphonesGetFWVersion(hp))
        if fwVersion != newFWVersion { fwVersion = newFWVersion }

        let newSeries = ModelSeriesType(rawValue: mdrHeadphonesGetModelSeries(hp)) ?? .noSeries
        if modelSeries != newSeries { modelSeries = newSeries }

        let newColor = ModelColor(rawValue: mdrHeadphonesGetModelColor(hp)) ?? .default
        if modelColor != newColor { modelColor = newColor }

        let newCodec = AudioCodec(rawValue: mdrHeadphonesGetAudioCodec(hp)) ?? .other
        if audioCodec != newCodec { audioCodec = newCodec }

        let newUpType = UpscalingType(rawValue: mdrHeadphonesGetUpscalingType(hp)) ?? .dsee
        if upscalingType != newUpType { upscalingType = newUpType }

        let newUpAvail = mdrHeadphonesGetUpscalingAvailable(hp) != 0
        if upscalingAvailable != newUpAvail { upscalingAvailable = newUpAvail }

        // Battery
        let newBattL = BatteryInfo(level: mdrHeadphonesGetBatteryLLevel(hp), threshold: mdrHeadphonesGetBatteryLThreshold(hp), charging: BatteryChargingStatus(rawValue: mdrHeadphonesGetBatteryLCharging(hp)) ?? .notCharging)
        if batteryL != newBattL { batteryL = newBattL }

        let newBattR = BatteryInfo(level: mdrHeadphonesGetBatteryRLevel(hp), threshold: mdrHeadphonesGetBatteryRThreshold(hp), charging: BatteryChargingStatus(rawValue: mdrHeadphonesGetBatteryRCharging(hp)) ?? .notCharging)
        if batteryR != newBattR { batteryR = newBattR }

        let newBattCase = BatteryInfo(level: mdrHeadphonesGetBatteryCaseLevel(hp), threshold: mdrHeadphonesGetBatteryCaseThreshold(hp), charging: BatteryChargingStatus(rawValue: mdrHeadphonesGetBatteryCaseCharging(hp)) ?? .notCharging)
        if batteryCase != newBattCase { batteryCase = newBattCase }

        // Playback metadata
        let newTitle = String(cString: mdrHeadphonesGetPlayTrackTitle(hp))
        if playTrackTitle != newTitle { playTrackTitle = newTitle }
        let newAlbum = String(cString: mdrHeadphonesGetPlayTrackAlbum(hp))
        if playTrackAlbum != newAlbum { playTrackAlbum = newAlbum }
        let newArtist = String(cString: mdrHeadphonesGetPlayTrackArtist(hp))
        if playTrackArtist != newArtist { playTrackArtist = newArtist }
        let newPlayPause = PlaybackStatus(rawValue: mdrHeadphonesGetPlayPause(hp)) ?? .unsettled
        if playPause != newPlayPause { playPause = newPlayPause }

        // NC/ASM - read current values (don't write back to C unless user changes)
        isPollingSuppressed = true
        defer { isPollingSuppressed = false }

        let newNcEnabled = mdrHeadphonesGetNcAsmEnabledCurrent(hp) != 0
        if ncAsmEnabled != newNcEnabled { ncAsmEnabled = newNcEnabled }
        let newNcFocus = mdrHeadphonesGetNcAsmFocusOnVoiceCurrent(hp) != 0
        if ncAsmFocusOnVoice != newNcFocus { ncAsmFocusOnVoice = newNcFocus }
        let newAmbient = mdrHeadphonesGetNcAsmAmbientLevelDesired(hp)
        if ncAsmAmbientLevel != newAmbient { ncAsmAmbientLevel = newAmbient }
        let newBtnFunc = ButtonFunction(rawValue: mdrHeadphonesGetNcAsmButtonFunctionDesired(hp)) ?? .noFunction
        if ncAsmButtonFunction != newBtnFunc { ncAsmButtonFunction = newBtnFunc }
        let newMode = NcAsmMode(rawValue: mdrHeadphonesGetNcAsmModeDesired(hp)) ?? .nc
        if ncAsmMode != newMode { ncAsmMode = newMode }
        let newAutoAsm = mdrHeadphonesGetNcAsmAutoAsmEnabledDesired(hp) != 0
        if ncAsmAutoAsmEnabled != newAutoAsm { ncAsmAutoAsmEnabled = newAutoAsm }
        let newAdaptSens = NoiseAdaptiveSensitivity(rawValue: mdrHeadphonesGetNcAsmNoiseAdaptiveSensitivityDesired(hp)) ?? .standard
        if ncAsmNoiseAdaptiveSensitivity != newAdaptSens { ncAsmNoiseAdaptiveSensitivity = newAdaptSens }

        // Power
        let newPowerAutoOff = AutoPowerOffElements(rawValue: mdrHeadphonesGetPowerAutoOffDesired(hp)) ?? .powerOffDisable
        if powerAutoOff != newPowerAutoOff { powerAutoOff = newPowerAutoOff }

        // Volume
        let newVol = mdrHeadphonesGetPlayVolumeDesired(hp)
        if playVolume != newVol { playVolume = newVol }

        // GS Params
        let newGS1 = mdrHeadphonesGetGsParamBoolDesired(hp, 1) != 0
        if gsParamBool1 != newGS1 { gsParamBool1 = newGS1 }
        let newGS2 = mdrHeadphonesGetGsParamBoolDesired(hp, 2) != 0
        if gsParamBool2 != newGS2 { gsParamBool2 = newGS2 }
        let newGS3 = mdrHeadphonesGetGsParamBoolDesired(hp, 3) != 0
        if gsParamBool3 != newGS3 { gsParamBool3 = newGS3 }
        let newGS4 = mdrHeadphonesGetGsParamBoolDesired(hp, 4) != 0
        if gsParamBool4 != newGS4 { gsParamBool4 = newGS4 }

        // GS Capabilities
        for i in 1...4 {
            let cap = GeneralSettingCapability(
                type: mdrHeadphonesGetGsCapabilityType(hp, Int32(i)),
                subject: String(cString: mdrHeadphonesGetGsCapabilitySubject(hp, Int32(i))),
                summary: String(cString: mdrHeadphonesGetGsCapabilitySummary(hp, Int32(i)))
            )
            switch i {
            case 1: if gsCapability1 != cap { gsCapability1 = cap }
            case 2: if gsCapability2 != cap { gsCapability2 = cap }
            case 3: if gsCapability3 != cap { gsCapability3 = cap }
            case 4: if gsCapability4 != cap { gsCapability4 = cap }
            default: break
            }
        }

        // Upscaling
        let newUpEnabled = mdrHeadphonesGetUpscalingEnabledDesired(hp) != 0
        if upscalingEnabled != newUpEnabled { upscalingEnabled = newUpEnabled }

        // Auto Pause
        let newAutoPause = mdrHeadphonesGetAutoPauseEnabledDesired(hp) != 0
        if autoPauseEnabled != newAutoPause { autoPauseEnabled = newAutoPause }

        // Touch
        let newTouchL = TouchPreset(rawValue: mdrHeadphonesGetTouchFunctionLeftDesired(hp)) ?? .noFunction
        if touchFunctionLeft != newTouchL { touchFunctionLeft = newTouchL }
        let newTouchR = TouchPreset(rawValue: mdrHeadphonesGetTouchFunctionRightDesired(hp)) ?? .noFunction
        if touchFunctionRight != newTouchR { touchFunctionRight = newTouchR }

        // Speak To Chat
        let newSTC = mdrHeadphonesGetSpeakToChatEnabledDesired(hp) != 0
        if speakToChatEnabled != newSTC { speakToChatEnabled = newSTC }
        let newSTCSens = DetectSensitivity(rawValue: mdrHeadphonesGetSpeakToChatDetectSensitivityDesired(hp)) ?? .auto_
        if speakToChatDetectSensitivity != newSTCSens { speakToChatDetectSensitivity = newSTCSens }
        let newSTCTime = ModeOutTime(rawValue: mdrHeadphonesGetSpeakToModeOutTimeDesired(hp)) ?? .mid
        if speakToModeOutTime != newSTCTime { speakToModeOutTime = newSTCTime }

        // Head Gesture
        let newHeadGesture = mdrHeadphonesGetHeadGestureEnabledDesired(hp) != 0
        if headGestureEnabled != newHeadGesture { headGestureEnabled = newHeadGesture }

        // EQ
        let newEqAvail = mdrHeadphonesGetEqAvailableCurrent(hp) != 0
        if eqAvailable != newEqAvail { eqAvailable = newEqAvail }
        let newEqPreset = EqPresetId(rawValue: mdrHeadphonesGetEqPresetIdDesired(hp)) ?? .off
        if eqPresetId != newEqPreset { eqPresetId = newEqPreset }
        let newClearBass = mdrHeadphonesGetEqClearBassDesired(hp)
        if eqClearBass != newClearBass { eqClearBass = newClearBass }

        let bandCount = Int(mdrHeadphonesGetEqBandCount(hp))
        if eqBands.count != bandCount {
            eqBands = (0..<bandCount).map { mdrHeadphonesGetEqBandValueDesired(hp, Int32($0)) }
        } else {
            for i in 0..<bandCount {
                let val = mdrHeadphonesGetEqBandValueDesired(hp, Int32(i))
                if eqBands[i] != val { eqBands[i] = val }
            }
        }

        // Voice Guidance
        let newVGEnabled = mdrHeadphonesGetVoiceGuidanceEnabledDesired(hp) != 0
        if voiceGuidanceEnabled != newVGEnabled { voiceGuidanceEnabled = newVGEnabled }
        let newVGVol = mdrHeadphonesGetVoiceGuidanceVolumeDesired(hp)
        if voiceGuidanceVolume != newVGVol { voiceGuidanceVolume = newVGVol }

        // Pairing
        let newPairing = mdrHeadphonesGetPairingModeDesired(hp) != 0
        if pairingMode != newPairing { pairingMode = newPairing }

        // Multipoint Mac
        let newMPMac = String(cString: mdrHeadphonesGetMultipointDeviceMacCurrent(hp))
        if multipointDeviceMac != newMPMac { multipointDeviceMac = newMPMac }

        // Paired Devices
        let deviceCount = Int(mdrHeadphonesGetPairedDeviceCount(hp))
        var newPaired: [PairedDevice] = []
        for i in 0..<deviceCount {
            let name = String(cString: mdrHeadphonesGetPairedDeviceName(hp, Int32(i)))
            let mac = String(cString: mdrHeadphonesGetPairedDeviceMac(hp, Int32(i)))
            let connected = mdrHeadphonesGetPairedDeviceConnected(hp, Int32(i)) != 0
            newPaired.append(PairedDevice(id: mac, name: name, connected: connected))
        }
        if pairedDevices != newPaired { pairedDevices = newPaired }

        // IsReady
        let newReady = mdrHeadphonesRequestIsReady(hp) == MDR_RESULT_OK
        if isReady != newReady { isReady = newReady }
    }
}
