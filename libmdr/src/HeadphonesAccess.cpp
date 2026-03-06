#include <mdr/Headphones.hpp>
#include <mdr-c/HeadphonesAccess.h>

#define H(p) reinterpret_cast<mdr::MDRHeadphones*>(p)

extern "C" {

// --- Read-only strings ---
const char* mdrHeadphonesGetUniqueId(MDRHeadphones* p) { return H(p)->mUniqueId.c_str(); }
const char* mdrHeadphonesGetFWVersion(MDRHeadphones* p) { return H(p)->mFWVersion.c_str(); }
const char* mdrHeadphonesGetModelName(MDRHeadphones* p) { return H(p)->mModelName.c_str(); }
uint8_t mdrHeadphonesGetModelSeries(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mModelSeries); }
uint8_t mdrHeadphonesGetModelColor(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mModelColor); }
uint8_t mdrHeadphonesGetAudioCodec(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mAudioCodec); }
uint8_t mdrHeadphonesGetUpscalingType(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mUpscalingType); }
int mdrHeadphonesGetUpscalingAvailable(MDRHeadphones* p) { return H(p)->mUpscalingAvailable ? 1 : 0; }

// --- Protocol ---
int mdrHeadphonesGetProtocolVersion(MDRHeadphones* p) { return H(p)->mProtocol.version; }
int mdrHeadphonesGetProtocolHasTable1(MDRHeadphones* p) { return H(p)->mProtocol.hasTable1; }
int mdrHeadphonesGetProtocolHasTable2(MDRHeadphones* p) { return H(p)->mProtocol.hasTable2; }

// --- Support Functions ---
int mdrHeadphonesSupportTable1(MDRHeadphones* p, uint8_t func) { return H(p)->mSupport.table1Functions[func] ? 1 : 0; }
int mdrHeadphonesSupportTable2(MDRHeadphones* p, uint8_t func) { return H(p)->mSupport.table2Functions[func] ? 1 : 0; }

// --- Battery ---
uint8_t mdrHeadphonesGetBatteryLLevel(MDRHeadphones* p) { return H(p)->mBatteryL.level; }
uint8_t mdrHeadphonesGetBatteryLThreshold(MDRHeadphones* p) { return H(p)->mBatteryL.threshold; }
uint8_t mdrHeadphonesGetBatteryLCharging(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mBatteryL.charging); }
uint8_t mdrHeadphonesGetBatteryRLevel(MDRHeadphones* p) { return H(p)->mBatteryR.level; }
uint8_t mdrHeadphonesGetBatteryRThreshold(MDRHeadphones* p) { return H(p)->mBatteryR.threshold; }
uint8_t mdrHeadphonesGetBatteryRCharging(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mBatteryR.charging); }
uint8_t mdrHeadphonesGetBatteryCaseLevel(MDRHeadphones* p) { return H(p)->mBatteryCase.level; }
uint8_t mdrHeadphonesGetBatteryCaseThreshold(MDRHeadphones* p) { return H(p)->mBatteryCase.threshold; }
uint8_t mdrHeadphonesGetBatteryCaseCharging(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mBatteryCase.charging); }

// --- Playback Metadata ---
const char* mdrHeadphonesGetPlayTrackTitle(MDRHeadphones* p) { return H(p)->mPlayTrackTitle.c_str(); }
const char* mdrHeadphonesGetPlayTrackAlbum(MDRHeadphones* p) { return H(p)->mPlayTrackAlbum.c_str(); }
const char* mdrHeadphonesGetPlayTrackArtist(MDRHeadphones* p) { return H(p)->mPlayTrackArtist.c_str(); }
uint8_t mdrHeadphonesGetPlayPause(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->mPlayPause); }

// --- Safe Listening ---
int mdrHeadphonesGetSafeListeningSoundPressure(MDRHeadphones* p) { return H(p)->mSafeListeningSoundPressure; }

// --- Paired Devices ---
int mdrHeadphonesGetPairedDeviceCount(MDRHeadphones* p) { return static_cast<int>(H(p)->mPairedDevices.size()); }
const char* mdrHeadphonesGetPairedDeviceName(MDRHeadphones* p, int index)
{
    auto& devices = H(p)->mPairedDevices;
    if (index < 0 || index >= static_cast<int>(devices.size())) return "";
    return devices[index].name.c_str();
}
const char* mdrHeadphonesGetPairedDeviceMac(MDRHeadphones* p, int index)
{
    auto& devices = H(p)->mPairedDevices;
    if (index < 0 || index >= static_cast<int>(devices.size())) return "";
    return devices[index].macAddress.c_str();
}
int mdrHeadphonesGetPairedDeviceConnected(MDRHeadphones* p, int index)
{
    auto& devices = H(p)->mPairedDevices;
    if (index < 0 || index >= static_cast<int>(devices.size())) return 0;
    return devices[index].connected ? 1 : 0;
}
uint8_t mdrHeadphonesGetPairedDevicesPlaybackDeviceID(MDRHeadphones* p) { return H(p)->mPairedDevicesPlaybackDeviceID; }

// --- GS Capabilities ---
static mdr::MDRHeadphones::GsCapability& gsCapAt(MDRHeadphones* p, int index)
{
    auto h = H(p);
    switch (index) {
    case 1: return h->mGsCapability1;
    case 2: return h->mGsCapability2;
    case 3: return h->mGsCapability3;
    case 4: return h->mGsCapability4;
    default: return h->mGsCapability1;
    }
}

uint8_t mdrHeadphonesGetGsCapabilityType(MDRHeadphones* p, int index)
{
    return static_cast<uint8_t>(gsCapAt(p, index).type);
}
const char* mdrHeadphonesGetGsCapabilitySubject(MDRHeadphones* p, int index)
{
    return gsCapAt(p, index).value.subject.value.c_str();
}
const char* mdrHeadphonesGetGsCapabilitySummary(MDRHeadphones* p, int index)
{
    return gsCapAt(p, index).value.summary.value.c_str();
}

// --- MDRProperty<bool> helpers ---
#define BOOL_PROP(Name, field) \
    int mdrHeadphonesGet##Name##Current(MDRHeadphones* p) { return H(p)->field.current ? 1 : 0; } \
    int mdrHeadphonesGet##Name##Desired(MDRHeadphones* p) { return H(p)->field.desired ? 1 : 0; } \
    void mdrHeadphonesSet##Name##Desired(MDRHeadphones* p, int v) { H(p)->field.desired = v != 0; }

#define INT_PROP(Name, field) \
    int32_t mdrHeadphonesGet##Name##Current(MDRHeadphones* p) { return H(p)->field.current; } \
    int32_t mdrHeadphonesGet##Name##Desired(MDRHeadphones* p) { return H(p)->field.desired; } \
    void mdrHeadphonesSet##Name##Desired(MDRHeadphones* p, int32_t v) { H(p)->field.desired = v; }

#define ENUM_PROP(Name, field, EnumType) \
    uint8_t mdrHeadphonesGet##Name##Current(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->field.current); } \
    uint8_t mdrHeadphonesGet##Name##Desired(MDRHeadphones* p) { return static_cast<uint8_t>(H(p)->field.desired); } \
    void mdrHeadphonesSet##Name##Desired(MDRHeadphones* p, uint8_t v) { H(p)->field.desired = static_cast<EnumType>(v); }

// Shutdown
int mdrHeadphonesGetShutdownDesired(MDRHeadphones* p) { return H(p)->mShutdown.desired ? 1 : 0; }
void mdrHeadphonesSetShutdownDesired(MDRHeadphones* p, int v) { H(p)->mShutdown.desired = v != 0; }

// NC/ASM
BOOL_PROP(NcAsmEnabled, mNcAsmEnabled)
BOOL_PROP(NcAsmFocusOnVoice, mNcAsmFocusOnVoice)
INT_PROP(NcAsmAmbientLevel, mNcAsmAmbientLevel)
ENUM_PROP(NcAsmButtonFunction, mNcAsmButtonFunction, mdr::v2::t1::Function)
ENUM_PROP(NcAsmMode, mNcAsmMode, mdr::v2::t1::NcAsmMode)
BOOL_PROP(NcAsmAutoAsmEnabled, mNcAsmAutoAsmEnabled)
ENUM_PROP(NcAsmNoiseAdaptiveSensitivity, mNcAsmNoiseAdaptiveSensitivity, mdr::v2::t1::NoiseAdaptiveSensitivity)

// Power Auto Off
ENUM_PROP(PowerAutoOff, mPowerAutoOff, mdr::v2::t1::AutoPowerOffElements)
ENUM_PROP(PowerAutoOffWearingDetection, mPowerAutoOffWearingDetection, mdr::v2::t1::AutoPowerOffWearingDetectionElements)

// Playback
INT_PROP(PlayVolume, mPlayVolume)
ENUM_PROP(PlayControl, mPlayControl, mdr::v2::t1::PlaybackControl)

// General Setting bools (indexed 1-4)
static mdr::MDRProperty<bool>& gsBoolAt(MDRHeadphones* p, int index)
{
    auto h = H(p);
    switch (index) {
    case 1: return h->mGsParamBool1;
    case 2: return h->mGsParamBool2;
    case 3: return h->mGsParamBool3;
    case 4: return h->mGsParamBool4;
    default: return h->mGsParamBool1;
    }
}
int mdrHeadphonesGetGsParamBoolCurrent(MDRHeadphones* p, int index) { return gsBoolAt(p, index).current ? 1 : 0; }
int mdrHeadphonesGetGsParamBoolDesired(MDRHeadphones* p, int index) { return gsBoolAt(p, index).desired ? 1 : 0; }
void mdrHeadphonesSetGsParamBoolDesired(MDRHeadphones* p, int index, int v) { gsBoolAt(p, index).desired = v != 0; }

// Upscaling Enabled
BOOL_PROP(UpscalingEnabled, mUpscalingEnabled)

// Audio Priority Mode
ENUM_PROP(AudioPriorityMode, mAudioPriorityMode, mdr::v2::t1::PriorMode)

// BGM Mode
BOOL_PROP(BGMModeEnabled, mBGMModeEnabled)
ENUM_PROP(BGMModeRoomSize, mBGMModeRoomSize, mdr::v2::t1::RoomSize)

// Upmix Cinema
BOOL_PROP(UpmixCinemaEnabled, mUpmixCinemaEnabled)

// Auto Pause
BOOL_PROP(AutoPauseEnabled, mAutoPauseEnabled)

// Touch Function
ENUM_PROP(TouchFunctionLeft, mTouchFunctionLeft, mdr::v2::t1::Preset)
ENUM_PROP(TouchFunctionRight, mTouchFunctionRight, mdr::v2::t1::Preset)

// Speak To Chat
BOOL_PROP(SpeakToChatEnabled, mSpeakToChatEnabled)
ENUM_PROP(SpeakToChatDetectSensitivity, mSpeakToChatDetectSensitivity, mdr::v2::t1::DetectSensitivity)
ENUM_PROP(SpeakToModeOutTime, mSpeakToModeOutTime, mdr::v2::t1::ModeOutTime)

// Head Gesture
BOOL_PROP(HeadGestureEnabled, mHeadGestureEnabled)

// Equalizer
int mdrHeadphonesGetEqAvailableCurrent(MDRHeadphones* p) { return H(p)->mEqAvailable.current ? 1 : 0; }

ENUM_PROP(EqPresetId, mEqPresetId, mdr::v2::t1::EqPresetId)
INT_PROP(EqClearBass, mEqClearBass)

int mdrHeadphonesGetEqBandCount(MDRHeadphones* p) { return static_cast<int>(H(p)->mEqConfig.desired.size()); }
int32_t mdrHeadphonesGetEqBandValueCurrent(MDRHeadphones* p, int index)
{
    auto& v = H(p)->mEqConfig.current;
    if (index < 0 || index >= static_cast<int>(v.size())) return 0;
    return v[index];
}
int32_t mdrHeadphonesGetEqBandValueDesired(MDRHeadphones* p, int index)
{
    auto& v = H(p)->mEqConfig.desired;
    if (index < 0 || index >= static_cast<int>(v.size())) return 0;
    return v[index];
}
void mdrHeadphonesSetEqBandValueDesired(MDRHeadphones* p, int index, int32_t value)
{
    auto& v = H(p)->mEqConfig.desired;
    if (index < 0 || index >= static_cast<int>(v.size())) return;
    v[index] = value;
}

// Voice Guidance
BOOL_PROP(VoiceGuidanceEnabled, mVoiceGuidanceEnabled)
INT_PROP(VoiceGuidanceVolume, mVoiceGuidanceVolume)

// Pairing Mode
BOOL_PROP(PairingMode, mPairingMode)

// Multipoint Device Mac
const char* mdrHeadphonesGetMultipointDeviceMacCurrent(MDRHeadphones* p) { return H(p)->mMultipointDeviceMac.current.c_str(); }
const char* mdrHeadphonesGetMultipointDeviceMacDesired(MDRHeadphones* p) { return H(p)->mMultipointDeviceMac.desired.c_str(); }
void mdrHeadphonesSetMultipointDeviceMacDesired(MDRHeadphones* p, const char* v) { H(p)->mMultipointDeviceMac.desired = v; }

// Paired Device Connect/Disconnect/Unpair
void mdrHeadphonesSetPairedDeviceDisconnectMacDesired(MDRHeadphones* p, const char* v) { H(p)->mPairedDeviceDisconnectMac.desired = v; }
void mdrHeadphonesSetPairedDeviceConnectMacDesired(MDRHeadphones* p, const char* v) { H(p)->mPairedDeviceConnectMac.desired = v; }
void mdrHeadphonesSetPairedDeviceUnpairMacDesired(MDRHeadphones* p, const char* v) { H(p)->mPairedDeviceUnpairMac.desired = v; }

// Safe Listening Preview Mode
BOOL_PROP(SafeListeningPreviewMode, mSafeListeningPreviewMode)

#undef H
#undef BOOL_PROP
#undef INT_PROP
#undef ENUM_PROP

}
