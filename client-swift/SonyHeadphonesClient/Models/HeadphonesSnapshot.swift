import Foundation

struct HeadphonesSnapshot: Codable {
    var isConnected: Bool
    var modelName: String
    var batteryL: Int
    var batteryR: Int
    var batteryCase: Int
    var batteryLCharging: Bool
    var batteryRCharging: Bool
    var batteryCaseCharging: Bool
    var ncMode: String
    var audioCodec: String
    var trackTitle: String
    var trackArtist: String
    var isPlaying: Bool
    var lastUpdated: Date

    static let suiteName = "group.com.YOURNAME.SoundPilot"
    static let key = "headphonesSnapshot"

    static func disconnected() -> HeadphonesSnapshot {
        HeadphonesSnapshot(
            isConnected: false,
            modelName: "",
            batteryL: 0, batteryR: 0, batteryCase: 0,
            batteryLCharging: false, batteryRCharging: false, batteryCaseCharging: false,
            ncMode: "off",
            audioCodec: "",
            trackTitle: "", trackArtist: "",
            isPlaying: false,
            lastUpdated: Date()
        )
    }
}
