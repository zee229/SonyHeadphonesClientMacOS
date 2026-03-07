import Foundation

/// Event codes returned by MDRHeadphones.pollEvents().
/// Matches C++ MDR_HEADPHONES_* constants from Base.h.
public enum MDREvent: Int, Sendable {
    // Status codes
    case error = -2
    case inProgress = -1
    case idle = 0

    // Event codes
    case unhandled = 1
    case ok = 2
    case alert = 3
    case deviceInfo = 4
    case supportFunctions = 5
    case codec = 6
    case ncAsmParam = 7
    case ncAsmButtonMode = 8
    case battery = 9
    case playbackMetadata = 10
    case playbackVolume = 11
    case playbackPlayPause = 12
    case soundPressure = 13
    case autoPowerOffParam = 14
    case autoPause = 15
    case voiceGuidanceEnable = 16
    case voiceGuidanceVolume = 17
    case speakToChatParam = 18
    case speakToChatEnabled = 19
    case headGesture = 20
    case listeningMode = 21
    case touchFunction = 22
    case equalizerAvailable = 23
    case equalizerParam = 24
    case connectionMode = 25
    case upscalingMode = 26
    case bluetoothMode = 27
    case multipointSwitch = 28
    case generalSetting1 = 29
    case generalSetting2 = 30
    case generalSetting3 = 31
    case generalSetting4 = 32
    case safeListeningParam = 33
    case connectedDevices = 34
    case interaction = 36

    // Task completion codes
    case taskInitOK = 100
    case taskSyncOK = 101
    case taskCommitOK = 102
}
