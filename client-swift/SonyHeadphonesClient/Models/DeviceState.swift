import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case discovering
    case connecting
    case connected
    case error(String)
}

struct BatteryInfo: Equatable {
    var level: UInt8 = 0
    var threshold: UInt8 = 0
    var charging: BatteryChargingStatus = .notCharging
}

struct PairedDevice: Identifiable, Equatable {
    let id: String // MAC address
    let name: String
    let connected: Bool
}

struct GeneralSettingCapability: Equatable {
    let type: UInt8 // GsSettingType raw value
    let subject: String
    let summary: String

    var isBoolType: Bool { type == 0x00 }
    var hasSubject: Bool { !subject.isEmpty }
    var hasSummary: Bool { !summary.isEmpty }

    var displaySubject: String {
        let map: [String: String] = [
            "MULTIPOINT_SETTING": "Connect to 2 devices simultaneously",
            "SIDETONE_SETTING": "Capture Voice During a Phone Call",
            "TOUCH_PANEL_SETTING": "Touch sensor control panel",
        ]
        return map[subject] ?? subject
    }

    var displaySummary: String {
        let map: [String: String] = [
            "MULTIPOINT_SETTING_SUMMARY":
                "For example, when using the audio device with both a PC and a smartphone, you can use it comfortably without needing to switch connections. During simultaneous connections, playback with the LDAC codec is not possible even if Prioritize Sound Quality is selected.",
            "MULTIPOINT_SETTING_SUMMARY_LDAC_AVAILABLE":
                "For example, when using the audio device with both a PC and a smartphone, you can use it comfortably without needing to switch connections.",
            "SIDETONE_SETTING_SUMMARY":
                "Your own voice will be easier to hear during calls. If your voice sounds too loud or background noise is distracting, please turn off this feature.",
        ]
        return map[summary] ?? summary
    }
}
