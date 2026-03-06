#pragma once
#include <stdint.h>
#include "Base.h"
#include "Headphones.h"

#ifdef __cplusplus
extern "C" {
#endif

// --- Read-only strings ---
const char* mdrHeadphonesGetUniqueId(MDRHeadphones*);
const char* mdrHeadphonesGetFWVersion(MDRHeadphones*);
const char* mdrHeadphonesGetModelName(MDRHeadphones*);
uint8_t mdrHeadphonesGetModelSeries(MDRHeadphones*);
uint8_t mdrHeadphonesGetModelColor(MDRHeadphones*);
uint8_t mdrHeadphonesGetAudioCodec(MDRHeadphones*);
uint8_t mdrHeadphonesGetUpscalingType(MDRHeadphones*);
int mdrHeadphonesGetUpscalingAvailable(MDRHeadphones*);

// --- Protocol ---
int mdrHeadphonesGetProtocolVersion(MDRHeadphones*);
int mdrHeadphonesGetProtocolHasTable1(MDRHeadphones*);
int mdrHeadphonesGetProtocolHasTable2(MDRHeadphones*);

// --- Support Functions ---
int mdrHeadphonesSupportTable1(MDRHeadphones*, uint8_t func);
int mdrHeadphonesSupportTable2(MDRHeadphones*, uint8_t func);

// --- Battery ---
uint8_t mdrHeadphonesGetBatteryLLevel(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryLThreshold(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryLCharging(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryRLevel(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryRThreshold(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryRCharging(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryCaseLevel(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryCaseThreshold(MDRHeadphones*);
uint8_t mdrHeadphonesGetBatteryCaseCharging(MDRHeadphones*);

// --- Playback Metadata ---
const char* mdrHeadphonesGetPlayTrackTitle(MDRHeadphones*);
const char* mdrHeadphonesGetPlayTrackAlbum(MDRHeadphones*);
const char* mdrHeadphonesGetPlayTrackArtist(MDRHeadphones*);
uint8_t mdrHeadphonesGetPlayPause(MDRHeadphones*);

// --- Safe Listening ---
int mdrHeadphonesGetSafeListeningSoundPressure(MDRHeadphones*);

// --- Paired Devices ---
int mdrHeadphonesGetPairedDeviceCount(MDRHeadphones*);
const char* mdrHeadphonesGetPairedDeviceName(MDRHeadphones*, int index);
const char* mdrHeadphonesGetPairedDeviceMac(MDRHeadphones*, int index);
int mdrHeadphonesGetPairedDeviceConnected(MDRHeadphones*, int index);
uint8_t mdrHeadphonesGetPairedDevicesPlaybackDeviceID(MDRHeadphones*);

// --- GS Capabilities ---
// 1-4
uint8_t mdrHeadphonesGetGsCapabilityType(MDRHeadphones*, int index);
const char* mdrHeadphonesGetGsCapabilitySubject(MDRHeadphones*, int index);
const char* mdrHeadphonesGetGsCapabilitySummary(MDRHeadphones*, int index);

// --- MDRProperty<bool> getters/setters ---
// Shutdown
int mdrHeadphonesGetShutdownDesired(MDRHeadphones*);
void mdrHeadphonesSetShutdownDesired(MDRHeadphones*, int value);

// NC/ASM
int mdrHeadphonesGetNcAsmEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetNcAsmEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmEnabledDesired(MDRHeadphones*, int value);

int mdrHeadphonesGetNcAsmFocusOnVoiceCurrent(MDRHeadphones*);
int mdrHeadphonesGetNcAsmFocusOnVoiceDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmFocusOnVoiceDesired(MDRHeadphones*, int value);

int32_t mdrHeadphonesGetNcAsmAmbientLevelCurrent(MDRHeadphones*);
int32_t mdrHeadphonesGetNcAsmAmbientLevelDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmAmbientLevelDesired(MDRHeadphones*, int32_t value);

uint8_t mdrHeadphonesGetNcAsmButtonFunctionCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetNcAsmButtonFunctionDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmButtonFunctionDesired(MDRHeadphones*, uint8_t value);

uint8_t mdrHeadphonesGetNcAsmModeCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetNcAsmModeDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmModeDesired(MDRHeadphones*, uint8_t value);

int mdrHeadphonesGetNcAsmAutoAsmEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetNcAsmAutoAsmEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmAutoAsmEnabledDesired(MDRHeadphones*, int value);

uint8_t mdrHeadphonesGetNcAsmNoiseAdaptiveSensitivityCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetNcAsmNoiseAdaptiveSensitivityDesired(MDRHeadphones*);
void mdrHeadphonesSetNcAsmNoiseAdaptiveSensitivityDesired(MDRHeadphones*, uint8_t value);

// Power Auto Off
uint8_t mdrHeadphonesGetPowerAutoOffCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetPowerAutoOffDesired(MDRHeadphones*);
void mdrHeadphonesSetPowerAutoOffDesired(MDRHeadphones*, uint8_t value);

uint8_t mdrHeadphonesGetPowerAutoOffWearingDetectionCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetPowerAutoOffWearingDetectionDesired(MDRHeadphones*);
void mdrHeadphonesSetPowerAutoOffWearingDetectionDesired(MDRHeadphones*, uint8_t value);

// Playback Volume
int32_t mdrHeadphonesGetPlayVolumeCurrent(MDRHeadphones*);
int32_t mdrHeadphonesGetPlayVolumeDesired(MDRHeadphones*);
void mdrHeadphonesSetPlayVolumeDesired(MDRHeadphones*, int32_t value);

// Playback Control
uint8_t mdrHeadphonesGetPlayControlCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetPlayControlDesired(MDRHeadphones*);
void mdrHeadphonesSetPlayControlDesired(MDRHeadphones*, uint8_t value);

// General Setting bools (1-4)
int mdrHeadphonesGetGsParamBoolCurrent(MDRHeadphones*, int index);
int mdrHeadphonesGetGsParamBoolDesired(MDRHeadphones*, int index);
void mdrHeadphonesSetGsParamBoolDesired(MDRHeadphones*, int index, int value);

// Upscaling Enabled
int mdrHeadphonesGetUpscalingEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetUpscalingEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetUpscalingEnabledDesired(MDRHeadphones*, int value);

// Audio Priority Mode
uint8_t mdrHeadphonesGetAudioPriorityModeCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetAudioPriorityModeDesired(MDRHeadphones*);
void mdrHeadphonesSetAudioPriorityModeDesired(MDRHeadphones*, uint8_t value);

// BGM Mode
int mdrHeadphonesGetBGMModeEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetBGMModeEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetBGMModeEnabledDesired(MDRHeadphones*, int value);

uint8_t mdrHeadphonesGetBGMModeRoomSizeCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetBGMModeRoomSizeDesired(MDRHeadphones*);
void mdrHeadphonesSetBGMModeRoomSizeDesired(MDRHeadphones*, uint8_t value);

// Upmix Cinema
int mdrHeadphonesGetUpmixCinemaEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetUpmixCinemaEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetUpmixCinemaEnabledDesired(MDRHeadphones*, int value);

// Auto Pause
int mdrHeadphonesGetAutoPauseEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetAutoPauseEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetAutoPauseEnabledDesired(MDRHeadphones*, int value);

// Touch Function L/R
uint8_t mdrHeadphonesGetTouchFunctionLeftCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetTouchFunctionLeftDesired(MDRHeadphones*);
void mdrHeadphonesSetTouchFunctionLeftDesired(MDRHeadphones*, uint8_t value);

uint8_t mdrHeadphonesGetTouchFunctionRightCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetTouchFunctionRightDesired(MDRHeadphones*);
void mdrHeadphonesSetTouchFunctionRightDesired(MDRHeadphones*, uint8_t value);

// Speak To Chat
int mdrHeadphonesGetSpeakToChatEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetSpeakToChatEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetSpeakToChatEnabledDesired(MDRHeadphones*, int value);

uint8_t mdrHeadphonesGetSpeakToChatDetectSensitivityCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetSpeakToChatDetectSensitivityDesired(MDRHeadphones*);
void mdrHeadphonesSetSpeakToChatDetectSensitivityDesired(MDRHeadphones*, uint8_t value);

uint8_t mdrHeadphonesGetSpeakToModeOutTimeCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetSpeakToModeOutTimeDesired(MDRHeadphones*);
void mdrHeadphonesSetSpeakToModeOutTimeDesired(MDRHeadphones*, uint8_t value);

// Head Gesture
int mdrHeadphonesGetHeadGestureEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetHeadGestureEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetHeadGestureEnabledDesired(MDRHeadphones*, int value);

// Equalizer
int mdrHeadphonesGetEqAvailableCurrent(MDRHeadphones*);

uint8_t mdrHeadphonesGetEqPresetIdCurrent(MDRHeadphones*);
uint8_t mdrHeadphonesGetEqPresetIdDesired(MDRHeadphones*);
void mdrHeadphonesSetEqPresetIdDesired(MDRHeadphones*, uint8_t value);

int32_t mdrHeadphonesGetEqClearBassCurrent(MDRHeadphones*);
int32_t mdrHeadphonesGetEqClearBassDesired(MDRHeadphones*);
void mdrHeadphonesSetEqClearBassDesired(MDRHeadphones*, int32_t value);

int mdrHeadphonesGetEqBandCount(MDRHeadphones*);
int32_t mdrHeadphonesGetEqBandValueCurrent(MDRHeadphones*, int index);
int32_t mdrHeadphonesGetEqBandValueDesired(MDRHeadphones*, int index);
void mdrHeadphonesSetEqBandValueDesired(MDRHeadphones*, int index, int32_t value);

// Voice Guidance
int mdrHeadphonesGetVoiceGuidanceEnabledCurrent(MDRHeadphones*);
int mdrHeadphonesGetVoiceGuidanceEnabledDesired(MDRHeadphones*);
void mdrHeadphonesSetVoiceGuidanceEnabledDesired(MDRHeadphones*, int value);

int32_t mdrHeadphonesGetVoiceGuidanceVolumeCurrent(MDRHeadphones*);
int32_t mdrHeadphonesGetVoiceGuidanceVolumeDesired(MDRHeadphones*);
void mdrHeadphonesSetVoiceGuidanceVolumeDesired(MDRHeadphones*, int32_t value);

// Pairing Mode
int mdrHeadphonesGetPairingModeCurrent(MDRHeadphones*);
int mdrHeadphonesGetPairingModeDesired(MDRHeadphones*);
void mdrHeadphonesSetPairingModeDesired(MDRHeadphones*, int value);

// Multipoint Device Mac
const char* mdrHeadphonesGetMultipointDeviceMacCurrent(MDRHeadphones*);
const char* mdrHeadphonesGetMultipointDeviceMacDesired(MDRHeadphones*);
void mdrHeadphonesSetMultipointDeviceMacDesired(MDRHeadphones*, const char* value);

// Paired Device Connect/Disconnect/Unpair Mac
void mdrHeadphonesSetPairedDeviceDisconnectMacDesired(MDRHeadphones*, const char* value);
void mdrHeadphonesSetPairedDeviceConnectMacDesired(MDRHeadphones*, const char* value);
void mdrHeadphonesSetPairedDeviceUnpairMacDesired(MDRHeadphones*, const char* value);

// Safe Listening Preview Mode
int mdrHeadphonesGetSafeListeningPreviewModeCurrent(MDRHeadphones*);
int mdrHeadphonesGetSafeListeningPreviewModeDesired(MDRHeadphones*);
void mdrHeadphonesSetSafeListeningPreviewModeDesired(MDRHeadphones*, int value);

#ifdef __cplusplus
}
#endif
