import SwiftUI

struct SystemTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
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
        let hasAny = manager.supports(.generalSetting1)
            || manager.supports(.generalSetting2)
            || manager.supports(.generalSetting3)
            || manager.supports(.generalSetting4)
        if hasAny {
            SoundCard {
                Label("General", systemImage: "gearshape")
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
    }

    @ViewBuilder
    private var touchPresetSection: some View {
        SoundCard {
            Label("Touch Controls", systemImage: "hand.tap")
                .font(.headline)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $manager.touchFunctionLeft) {
                        ForEach(TouchPreset.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .labelsHidden()
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $manager.touchFunctionRight) {
                        ForEach(TouchPreset.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .labelsHidden()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var ncAsmButtonSection: some View {
        SoundCard {
            Label("NC/AMB Button", systemImage: "button.programmable")
                .font(.headline)
            Picker("Function", selection: $manager.ncAsmButtonFunction) {
                ForEach(ButtonFunction.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private var headGestureSection: some View {
        SoundCard {
            HStack {
                Label("Head Gesture", systemImage: "face.smiling")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $manager.headGestureEnabled)
                    .labelsHidden()
            }
        }
    }

    @ViewBuilder
    private var autoPowerOffSection: some View {
        let supportAutoOff = manager.supports(.autoPowerOff)
        let supportAutoOffWear = manager.supports(.autoPowerOffWithWearingDetection)
        if supportAutoOff || supportAutoOffWear {
            SoundCard {
                Label("Auto Power Off", systemImage: "timer")
                    .font(.headline)
                Picker("Time", selection: $manager.powerAutoOff) {
                    ForEach(AutoPowerOffElements.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var autoPauseSection: some View {
        SoundCard {
            HStack {
                Label("Pause When Removed", systemImage: "earbuds")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $manager.autoPauseEnabled)
                    .labelsHidden()
            }
        }
    }

    @ViewBuilder
    private var voiceGuidanceSection: some View {
        SoundCard {
            HStack {
                Label("Voice Guidance", systemImage: "speaker.badge.exclamationmark")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $manager.voiceGuidanceEnabled)
                    .labelsHidden()
            }

            if manager.supports(.voiceGuidanceSettingVolAdj) {
                VStack(spacing: 4) {
                    HStack {
                        Text("Volume")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(manager.voiceGuidanceVolume)")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
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
                HStack {
                    Text(capability.displaySubject)
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $value)
                        .labelsHidden()
                }
                if capability.hasSummary {
                    Text(capability.displaySummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
