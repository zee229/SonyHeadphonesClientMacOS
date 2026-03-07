import Foundation

// T2 enums from ProtocolV2T2.hpp
// Namespace: mdr::v2::t2


public enum T2ConnectInquiredType: UInt8, Sendable {
    case FIXED_VALUE = 0
}

public enum PeripheralInquiredType: UInt8, Sendable {
    case PAIRING_DEVICE_MANAGEMENT_CLASSIC_BT = 0x00
    case SOURCE_SWITCH_CONTROL = 0x01
    case PAIRING_DEVICE_MANAGEMENT_WITH_BLUETOOTH_CLASS_OF_DEVICE = 0x02
    case MUSIC_HAND_OVER_SETTING = 0x03
}

public enum PeripheralBluetoothMode: UInt8, Sendable {
    case NORMAL_MODE = 0x00
    case INQUIRY_SCAN_MODE = 0x01
}

public enum ConnectivityActionType: UInt8, Sendable {
    case DISCONNECT = 0x00
    case CONNECT = 0x01
    case UNPAIR = 0x02
}

public enum PeripheralResult: UInt8, Sendable {
    case DISCONNECTION_SUCCESS = 0x00
    case DISCONNECTION_ERROR = 0x01
    case DISCONNECTION_IN_PROGRESS = 0x02
    case DISCONNECTION_BUSY = 0x03
    case CONNECTION_SUCCESS = 0x10
    case CONNECTION_ERROR = 0x11
    case CONNECTION_IN_PROGRESS = 0x12
    case CONNECTION_BUSY = 0x13
    case UNPAIRING_SUCCESS = 0x20
    case UNPAIRING_ERROR = 0x21
    case UNPAIRING_IN_PROGRESS = 0x22
    case UNPAIRING_BUSY = 0x23
    case PAIRING_SUCCESS = 0x30
    case PAIRING_ERROR = 0x31
    case PAIRING_IN_PROGRESS = 0x32
    case PAIRING_BUSY = 0x33
}

public enum SourceSwitchControlResult: UInt8, Sendable {
    case SUCCESS = 0x00
    case FAIL = 0x01
    case FAIL_CALLING = 0x02
    case FAIL_A2DP_NOT_CONNECT = 0x03
    case FAIL_GIVE_PRIORITY_TO_VOICE_ASSISTANT = 0x04
}

public enum VoiceGuidanceInquiredType: UInt8, Sendable {
    case MTK_TRANSFER_WO_DISCONNECTION_NOT_SUPPORT_LANGUAGE_SWITCH = 0x0
    case MTK_TRANSFER_WO_DISCONNECTION_SUPPORT_LANGUAGE_SWITCH = 0x1
    case SUPPORT_LANGUAGE_SWITCH = 0x2
    case ONLY_ON_OFF_SETTING = 0x3
    case VOLUME = 0x20
    case VOLUME_SETTING_FIXED_TO_5_STEPS = 0x21
    case BATTERY_LV_VOICE = 0x30
    case POWER_ONOFF_SOUND = 0x31
    case SOUNDEFFECT_ULT_BEEP_ONOFF = 0x32
}

public enum VoiceGuidanceLanguage: UInt8, Sendable {
    case UNDEFINED_LANGUAGE = 0x00
    case ENGLISH = 0x01
    case FRENCH = 0x02
    case GERMAN = 0x03
    case SPANISH = 0x04
    case ITALIAN = 0x05
    case PORTUGUESE = 0x06
    case DUTCH = 0x07
    case SWEDISH = 0x08
    case FINNISH = 0x09
    case RUSSIAN = 0x0A
    case JAPANESE = 0x0B
    case BRAZILIAN_PORTUGUESE = 0x0D
    case KOREAN = 0x0F
    case TURKISH = 0x10
    case CHINESE = 0xF0
}

public enum SafeListeningInquiredType: UInt8, Sendable {
    case SAFE_LISTENING_HBS_1 = 0x0
    case SAFE_LISTENING_TWS_1 = 0x1
    case SAFE_LISTENING_HBS_2 = 0x2
    case SAFE_LISTENING_TWS_2 = 0x3
    case SAFE_VOLUME_CONTROL = 0x4
}

public enum SafeListeningErrorCause: UInt8, Sendable {
    case NOT_PLAYING = 0x0
    case IN_CALL = 0x1
    case DETACHED = 0x2
}

public enum SafeListeningTargetType: UInt8, Sendable {
    case HBS = 0x00
    case TWS_L = 0x01
    case TWS_R = 0x02
}

public enum SafeListeningLogDataStatus: UInt8, Sendable {
    case DISCONNECTED = 0x00
    case SENDING = 0x01
    case COMPLETED = 0x02
    case NOT_SENDING = 0x03
    case ERROR = 0x04
}

public enum SafeListeningWHOStandardLevel: UInt8, Sendable {
    case NORMAL = 0x0
    case SENSITIVE = 0x1
}

