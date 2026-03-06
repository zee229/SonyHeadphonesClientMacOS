import SwiftUI

struct SoundTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    private var supportNC: Bool {
        manager.supports(.noiseCancellingOnOff)
        || manager.supports(.noiseCancellingOnOffAndASMOnOff)
        || manager.supports(.ncDualSingleOffAndASMOnOff)
        || manager.supports(.ncOnOffAndASMLevelAdj)
        || manager.supports(.ncDualSingleOffASMLevelAdj)
        || manager.supports(.modeNcAsmDualAutoASMLevelAdj)
        || manager.supports(.modeNcAsmDualSingleASMLevelAdj)
        || manager.supports(.modeNcAsmDualASMLevelAdj)
        || manager.supports(.modeNcNcssAsmDualASMLevelAdjWithTestMode)
        || manager.supports(.modeNcAsmDualASMLevelAdjNoiseAdaptation)
    }

    private var supportASM: Bool {
        manager.supports(.noiseCancellingOnOffAndASMOnOff)
        || manager.supports(.ncDualSingleOffAndASMOnOff)
        || manager.supports(.ncOnOffAndASMLevelAdj)
        || manager.supports(.ncDualSingleOffASMLevelAdj)
        || manager.supports(.asmOnOff)
        || manager.supports(.asmLevelAdj)
        || manager.supports(.modeNcAsmDualAutoASMLevelAdj)
        || manager.supports(.ambientSoundControlModeSelect)
        || manager.supports(.modeNcAsmDualSingleASMLevelAdj)
        || manager.supports(.modeNcAsmDualASMLevelAdj)
        || manager.supports(.modeNcNcssAsmDualASMLevelAdjWithTestMode)
        || manager.supports(.modeNcAsmDualASMLevelAdjNoiseAdaptation)
    }

    private var supportAutoASM: Bool {
        manager.supports(.modeNcAsmDualASMLevelAdjNoiseAdaptation)
    }

    private var ncAsmSelection: Int {
        if !manager.ncAsmEnabled { return 2 }
        if supportNC && supportASM {
            return manager.ncAsmMode == .nc ? 0 : 1
        }
        return supportNC ? 0 : 1
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if supportNC || supportASM {
                    ambientSoundSection
                }

                if manager.supports(.smartTalkingModeType2) {
                    speakToChatSection
                }

                equalizerSection
            }
            .padding()
        }
    }

    @ViewBuilder
    private var ambientSoundSection: some View {
        SoundCard {
            Label("Ambient Sound", systemImage: "ear")
                .font(.headline)

            // Mode picker as segmented-style pills
            HStack(spacing: 6) {
                if supportNC {
                    ModePill(
                        title: "NC",
                        icon: "minus.circle",
                        isSelected: manager.ncAsmEnabled && (!supportASM || manager.ncAsmMode == .nc)
                    ) {
                        manager.ncAsmEnabled = true
                        manager.ncAsmMode = .nc
                    }
                }
                if supportASM {
                    ModePill(
                        title: "Ambient",
                        icon: "wind",
                        isSelected: manager.ncAsmEnabled && (!supportNC || manager.ncAsmMode == .asm_)
                    ) {
                        manager.ncAsmEnabled = true
                        manager.ncAsmMode = .asm_
                        if manager.ncAsmAmbientLevel == 0 {
                            manager.ncAsmAmbientLevel = 20
                        }
                    }
                }
                ModePill(
                    title: "Off",
                    icon: "power",
                    isSelected: !manager.ncAsmEnabled
                ) {
                    manager.ncAsmEnabled = false
                }
            }

            // Ambient strength
            VStack(spacing: 4) {
                HStack {
                    Text("Ambient Strength")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(manager.ncAsmAmbientLevel)")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.accentColor)
                }
                Slider(
                    value: Binding(
                        get: { Double(manager.ncAsmAmbientLevel) },
                        set: { manager.ncAsmAmbientLevel = Int32($0) }
                    ),
                    in: 1...20,
                    step: 1
                )
            }

            if supportAutoASM {
                Toggle("Auto Ambient Sound", isOn: $manager.ncAsmAutoAsmEnabled)
                    .font(.subheadline)
                if manager.ncAsmAutoAsmEnabled {
                    Picker("Sensitivity", selection: $manager.ncAsmNoiseAdaptiveSensitivity) {
                        ForEach(NoiseAdaptiveSensitivity.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    .font(.subheadline)
                }
            }

            Toggle("Voice Passthrough", isOn: $manager.ncAsmFocusOnVoice)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private var speakToChatSection: some View {
        SoundCard {
            HStack {
                Label("Speak To Chat", systemImage: "message")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $manager.speakToChatEnabled)
                    .labelsHidden()
            }

            if manager.speakToChatEnabled {
                Picker("Sensitivity", selection: $manager.speakToChatDetectSensitivity) {
                    ForEach(DetectSensitivity.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .font(.subheadline)
                Picker("Timeout", selection: $manager.speakToModeOutTime) {
                    ForEach(ModeOutTime.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var equalizerSection: some View {
        SoundCard {
            Label("Equalizer", systemImage: "slider.vertical.3")
                .font(.headline)

            Picker("Preset", selection: $manager.eqPresetId) {
                ForEach(EqPresetId.allCases, id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }
            .font(.subheadline)

            if !manager.eqBands.isEmpty {
                EqualizerView(bands: manager.eqBands) { index, value in
                    manager.setEqBandValue(index: index, value: value)
                }

                if manager.eqBands.count == 5 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Clear Bass")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(manager.eqClearBass)")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.accentColor)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(manager.eqClearBass) },
                                set: { manager.eqClearBass = Int32($0) }
                            ),
                            in: -10...10,
                            step: 1
                        )
                    }
                }
            }
        }

        // DSEE as separate card
        SoundCard {
            HStack {
                Label("DSEE", systemImage: "waveform.badge.magnifyingglass")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { manager.upscalingEnabled },
                    set: { manager.upscalingEnabled = $0 }
                ))
                .labelsHidden()
                .disabled(!manager.upscalingAvailable)
            }

            if manager.upscalingEnabled {
                Text("DSEE HX AI upscales compressed audio in real-time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Reusable Components

struct SoundCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

struct ModePill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct EqualizerView: View {
    let bands: [Int32]
    let onChange: (Int, Int32) -> Void

    private var bandLabels5: [String] { ["400", "1k", "2.5k", "6.3k", "16k"] }
    private var bandLabels10: [String] { ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"] }

    var body: some View {
        let labels = bands.count == 5 ? bandLabels5 : (bands.count == 10 ? bandLabels10 : [])
        let mn = bands.count == 5 ? -10 : -6
        let mx = bands.count == 5 ? 10 : 6

        if !labels.isEmpty {
            VStack(spacing: 8) {
                Text(bands.count == 5 ? "5-Band EQ" : "10-Band EQ")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .bottom, spacing: 0) {
                    // dB scale on the left
                    VStack {
                        Text("+\(mx)").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
                        Spacer()
                        Text("0").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
                        Spacer()
                        Text("\(mn)").font(.system(size: 9, design: .monospaced)).foregroundColor(.secondary)
                    }
                    .frame(width: 28, height: 160)
                    .padding(.bottom, 20)

                    // Band sliders
                    ForEach(0..<bands.count, id: \.self) { i in
                        VStack(spacing: 6) {
                            // Value label on top
                            Text("\(bands[i])")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.accentColor)
                                .frame(height: 14)

                            // Custom vertical slider
                            EQBandSlider(
                                value: Binding(
                                    get: { Int(bands[i]) },
                                    set: { onChange(i, Int32($0)) }
                                ),
                                range: mn...mx
                            )
                            .frame(height: 160)

                            // Frequency label
                            Text(labels[i])
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct EQBandSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var isDragging = false

    private var totalSteps: Int { range.upperBound - range.lowerBound }
    private var normalizedValue: Double {
        Double(value - range.lowerBound) / Double(totalSteps)
    }

    var body: some View {
        GeometryReader { geo in
            let trackWidth: CGFloat = 4
            let thumbSize: CGFloat = 16
            let trackHeight = geo.size.height - thumbSize
            let centerX = geo.size.width / 2
            let zeroY = thumbSize / 2 + trackHeight * (1.0 - Double(-range.lowerBound) / Double(totalSteps))
            let thumbY = thumbSize / 2 + trackHeight * (1.0 - normalizedValue)

            ZStack {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(nsColor: .separatorColor))
                    .frame(width: trackWidth, height: trackHeight)
                    .position(x: centerX, y: geo.size.height / 2)

                // Zero line
                Rectangle()
                    .fill(Color(nsColor: .tertiaryLabelColor))
                    .frame(width: 12, height: 1)
                    .position(x: centerX, y: zeroY)

                // Filled portion from zero to thumb
                let fillTop = min(zeroY, thumbY)
                let fillBottom = max(zeroY, thumbY)
                let fillHeight = fillBottom - fillTop
                if fillHeight > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(width: trackWidth, height: fillHeight)
                        .position(x: centerX, y: fillTop + fillHeight / 2)
                }

                // Thumb
                Circle()
                    .fill(isDragging ? Color.accentColor : Color.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .frame(width: thumbSize, height: thumbSize)
                    .position(x: centerX, y: thumbY)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let fraction = 1.0 - (drag.location.y - thumbSize / 2) / trackHeight
                        let clamped = min(max(fraction, 0), 1)
                        let newValue = range.lowerBound + Int(round(clamped * Double(totalSteps)))
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
}
