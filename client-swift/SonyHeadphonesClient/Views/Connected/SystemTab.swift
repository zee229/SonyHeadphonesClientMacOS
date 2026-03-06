import SwiftUI

struct SystemTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // General Settings
                generalSettingsSection

                // Touch Preset
                if manager.supports(.assignableSetting) {
                    touchPresetSection
                }

                // NC/ASM Button Function
                if manager.supports(.ambientSoundControlModeSelect) {
                    ncAsmButtonSection
                }

                // Head Gesture
                if manager.supports(.headGestureOnOffTraining) {
                    headGestureSection
                }

                // Auto Power Off
                autoPowerOffSection

                // Auto Pause
                if manager.supports(.playbackControlByWearingRemovingOnOff) {
                    autoPauseSection
                }

                // Voice Guidance
                voiceGuidanceSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var generalSettingsSection: some View {
        Section {
            Text("General Setting")
                .font(.headline)

            if manager.supports(.generalSetting1) {
                GeneralSettingRow(capability: manager.gsCapability1, value: $manager.gsParamBool1)
            }
            if manager.supports(.generalSetting2) {
                GeneralSettingRow(capability: manager.gsCapability2, value: $manager.gsParamBool2)
            }
            if manager.supports(.generalSetting3) {
                GeneralSettingRow(capability: manager.gsCapability3, value: $manager.gsParamBool3)
            }
            if manager.supports(.generalSetting4) {
                GeneralSettingRow(capability: manager.gsCapability4, value: $manager.gsParamBool4)
            }
        }
    }

    @ViewBuilder
    private var touchPresetSection: some View {
        Section {
            Text("Touch Preset")
                .font(.headline)
            Picker("Left Touch", selection: $manager.touchFunctionLeft) {
                ForEach(TouchPreset.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            Picker("Right Touch", selection: $manager.touchFunctionRight) {
                ForEach(TouchPreset.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
        }
    }

    @ViewBuilder
    private var ncAsmButtonSection: some View {
        Section {
            Text("NC/AMB Button Function")
                .font(.headline)
            Picker("Function", selection: $manager.ncAsmButtonFunction) {
                ForEach(ButtonFunction.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
        }
    }

    @ViewBuilder
    private var headGestureSection: some View {
        Section {
            Text("Head Gesture")
                .font(.headline)
            Toggle("Enabled", isOn: $manager.headGestureEnabled)
        }
    }

    @ViewBuilder
    private var autoPowerOffSection: some View {
        let supportAutoOff = manager.supports(.autoPowerOff)
        let supportAutoOffWear = manager.supports(.autoPowerOffWithWearingDetection)
        if supportAutoOff || supportAutoOffWear {
            Section {
                Text("Auto Power Off")
                    .font(.headline)
                Picker("Time", selection: $manager.powerAutoOff) {
                    ForEach(AutoPowerOffElements.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var autoPauseSection: some View {
        Section {
            Text("Pause when removed")
                .font(.headline)
            Toggle("Enabled", isOn: $manager.autoPauseEnabled)
        }
    }

    @ViewBuilder
    private var voiceGuidanceSection: some View {
        Section {
            Text("Voice Guidance")
                .font(.headline)
            Toggle("Enabled", isOn: $manager.voiceGuidanceEnabled)
            if manager.supports(.voiceGuidanceSettingVolAdj) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume")
                        .font(.subheadline)
                    Slider(
                        value: Binding(
                            get: { Double(manager.voiceGuidanceVolume) },
                            set: { manager.voiceGuidanceVolume = Int32($0) }
                        ),
                        in: -2...2,
                        step: 1
                    )
                }
            }
        }
    }
}

struct GeneralSettingRow: View {
    let capability: GeneralSettingCapability
    @Binding var value: Bool

    var body: some View {
        if capability.isBoolType && capability.hasSubject {
            VStack(alignment: .leading, spacing: 4) {
                Toggle(capability.displaySubject, isOn: $value)
                if capability.hasSummary {
                    Text(capability.displaySummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
