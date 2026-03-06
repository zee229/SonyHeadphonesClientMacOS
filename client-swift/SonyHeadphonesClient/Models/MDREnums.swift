import Foundation

enum AudioCodec: UInt8, CaseIterable {
    case unsettled = 0x00
    case sbc = 0x01
    case aac = 0x02
    case ldac = 0x10
    case aptX = 0x20
    case aptXHD = 0x21
    case lc3 = 0x30
    case other = 0xFF

    var displayName: String {
        switch self {
        case .unsettled: return "<unsettled>"
        case .sbc: return "SBC"
        case .aac: return "AAC"
        case .ldac: return "LDAC"
        case .aptX: return "aptX"
        case .aptXHD: return "aptX HD"
        case .lc3: return "LC3"
        case .other: return "Unknown"
        }
    }
}

enum UpscalingType: UInt8 {
    case dseeHX = 0x00
    case dsee = 0x01
    case dseeHXAI = 0x02
    case dseeUltimate = 0x03

    var displayName: String {
        switch self {
        case .dseeHX: return "DSEE HX"
        case .dsee: return "DSEE"
        case .dseeHXAI: return "DSEE HX AI"
        case .dseeUltimate: return "DSEE ULTIMATE"
        }
    }
}

enum BatteryChargingStatus: UInt8 {
    case notCharging = 0
    case charging = 1
    case unknown = 2
    case charged = 3

    var displayName: String {
        switch self {
        case .notCharging: return ""
        case .charging: return "Charging"
        case .unknown: return "Unknown"
        case .charged: return "Charged"
        }
    }
}

enum NcAsmMode: UInt8 {
    case nc = 0
    case asm_ = 1
}

enum NoiseAdaptiveSensitivity: UInt8, CaseIterable {
    case standard = 0
    case high = 1
    case low = 2

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .high: return "High"
        case .low: return "Low"
        }
    }
}

enum DetectSensitivity: UInt8, CaseIterable {
    case auto_ = 0x00
    case high = 0x01
    case low = 0x02

    var displayName: String {
        switch self {
        case .auto_: return "Auto"
        case .high: return "High"
        case .low: return "Low"
        }
    }
}

enum ModeOutTime: UInt8, CaseIterable {
    case fast = 0x00
    case mid = 0x01
    case slow = 0x02
    case none = 0x03

    var displayName: String {
        switch self {
        case .fast: return "Short (~5s)"
        case .mid: return "Standard (~15s)"
        case .slow: return "Long (~30s)"
        case .none: return "Don't end automatically"
        }
    }
}

enum EqPresetId: UInt8, CaseIterable {
    case off = 0x00
    case rock = 0x01
    case pop = 0x02
    case jazz = 0x03
    case dance = 0x04
    case edm = 0x05
    case rAndBHipHop = 0x06
    case acoustic = 0x07
    case bright = 0x10
    case excited = 0x11
    case mellow = 0x12
    case relaxed = 0x13
    case vocal = 0x14
    case treble = 0x15
    case bass = 0x16
    case speech = 0x17
    case custom = 0xA0
    case userSetting1 = 0xA1
    case userSetting2 = 0xA2
    case userSetting3 = 0xA3
    case userSetting4 = 0xA4
    case userSetting5 = 0xA5

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .rock: return "Rock"
        case .pop: return "Pop"
        case .jazz: return "Jazz"
        case .dance: return "Dance"
        case .edm: return "EDM"
        case .rAndBHipHop: return "R&B/Hip-Hop"
        case .acoustic: return "Acoustic"
        case .bright: return "Bright"
        case .excited: return "Excited"
        case .mellow: return "Mellow"
        case .relaxed: return "Relaxed"
        case .vocal: return "Vocal"
        case .treble: return "Treble"
        case .bass: return "Bass"
        case .speech: return "Speech"
        case .custom: return "Custom"
        case .userSetting1: return "User Setting 1"
        case .userSetting2: return "User Setting 2"
        case .userSetting3: return "User Setting 3"
        case .userSetting4: return "User Setting 4"
        case .userSetting5: return "User Setting 5"
        }
    }
}

enum TouchPreset: UInt8, CaseIterable {
    case playbackControl = 0x20
    case ambientSoundControlQuickAccess = 0x35
    case noFunction = 0xFF

    var displayName: String {
        switch self {
        case .playbackControl: return "Playback Control"
        case .ambientSoundControlQuickAccess: return "Ambient Sound Control"
        case .noFunction: return "No Function"
        }
    }
}

enum ButtonFunction: UInt8, CaseIterable {
    case noFunction = 0x00
    case ncAsmOff = 0x01
    case ncAsm = 0x02
    case ncOff = 0x03
    case asmOff = 0x04

    var displayName: String {
        switch self {
        case .noFunction: return "No Function"
        case .ncAsmOff: return "NC-ASM-OFF"
        case .ncAsm: return "NC-ASM"
        case .ncOff: return "NC-OFF"
        case .asmOff: return "ASM-OFF"
        }
    }
}

enum AutoPowerOffElements: UInt8, CaseIterable {
    case powerOffIn5Min = 0x00
    case powerOffIn30Min = 0x01
    case powerOffIn60Min = 0x02
    case powerOffIn180Min = 0x03
    case powerOffIn15Min = 0x04
    case powerOffDisable = 0x11

    var displayName: String {
        switch self {
        case .powerOffIn5Min: return "5 minutes of no Bluetooth connection"
        case .powerOffIn15Min: return "15 minutes of no Bluetooth connection"
        case .powerOffIn30Min: return "30 minutes of no Bluetooth connection"
        case .powerOffIn60Min: return "1 hour of no Bluetooth connection"
        case .powerOffIn180Min: return "3 hours of no Bluetooth connection"
        case .powerOffDisable: return "Do not turn off"
        }
    }
}

enum PlaybackStatus: UInt8 {
    case unsettled = 0x00
    case play = 0x01
    case pause = 0x02
    case stop = 0x03
}

enum PlaybackControl: UInt8 {
    case keyOff = 0x00
    case pause = 0x01
    case trackUp = 0x02
    case trackDown = 0x03
    case stop = 0x06
    case play = 0x07
}

enum ModelSeriesType: UInt8 {
    case noSeries = 0
    case extraBass = 0x10
    case ultPowerSound = 0x11
    case hear = 0x20
    case premium = 0x30
    case sports = 0x40
    case casual = 0x50
    case linkBuds = 0x60
    case neckband = 0x70
    case linkpod = 0x80
    case gaming = 0x90

    var displayName: String {
        switch self {
        case .noSeries: return "No Series"
        case .extraBass: return "EXTRA BASS"
        case .ultPowerSound: return "ULT POWER SOUND"
        case .hear: return "h.ear"
        case .premium: return "Premium"
        case .sports: return "Sports"
        case .casual: return "Casual"
        case .linkBuds: return "LinkBuds"
        case .neckband: return "Neckband"
        case .linkpod: return "LinkPod"
        case .gaming: return "Gaming"
        }
    }
}

enum ModelColor: UInt8 {
    case `default` = 0
    case black = 1
    case white = 2
    case silver = 3
    case red = 4
    case blue = 5
    case pink = 6
    case yellow = 7
    case green = 8
    case gray = 9
    case gold = 10
    case cream = 11
    case orange = 12
    case brown = 13
    case violet = 14

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .black: return "Black"
        case .white: return "White"
        case .silver: return "Silver"
        case .red: return "Red"
        case .blue: return "Blue"
        case .pink: return "Pink"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .gray: return "Gray"
        case .gold: return "Gold"
        case .cream: return "Cream"
        case .orange: return "Orange"
        case .brown: return "Brown"
        case .violet: return "Violet"
        }
    }
}

// Support function table1 enum values the UI cares about
enum SupportFunctionT1: UInt8 {
    case codecIndicator = 0x12
    case upscalingIndicator = 0x13
    case batteryLevelIndicator = 0x20
    case leftRightBatteryLevelIndicator = 0x21
    case cradleBatteryLevelIndicator = 0x22
    case powerOff = 0x23
    case autoPowerOff = 0x24
    case autoPowerOffWithWearingDetection = 0x25
    case batteryLevelWithThreshold = 0x28
    case lrBatteryLevelWithThreshold = 0x29
    case cradleBatteryLevelWithThreshold = 0x2A
    case presetEQ = 0x50
    case noiseCancellingOnOff = 0x61
    case noiseCancellingOnOffAndASMOnOff = 0x62
    case ncDualSingleOffAndASMOnOff = 0x63
    case ncOnOffAndASMLevelAdj = 0x64
    case ncDualSingleOffASMLevelAdj = 0x65
    case asmOnOff = 0x66
    case asmLevelAdj = 0x67
    case modeNcAsmDualAutoASMLevelAdj = 0x68
    case ambientSoundControlModeSelect = 0x69
    case modeNcAsmDualSingleASMLevelAdj = 0x6A
    case modeNcAsmDualASMLevelAdj = 0x6B
    case modeNcNcssAsmDualASMLevelAdjWithTestMode = 0x6C
    case modeNcAsmDualASMLevelAdjNoiseAdaptation = 0x6D
    case generalSetting1 = 0xD1
    case generalSetting2 = 0xD2
    case generalSetting3 = 0xD3
    case generalSetting4 = 0xD4
    case playbackControlByWearingRemovingOnOff = 0xF1
    case smartTalkingModeType2 = 0xFC
    case assignableSetting = 0xF3
    case headGestureOnOffTraining = 0xFF
    case listeningOption = 0xE6
}

enum SupportFunctionT2: UInt8 {
    case pairingDeviceManagementClassicBT = 0x30
    case pairingDeviceManagementWithBTClassOfDeviceClassicBT = 0x32
    case pairingDeviceManagementWithBTClassOfDeviceClassicLE = 0x33
    case voiceGuidanceSettingVolAdj = 0x42
}
