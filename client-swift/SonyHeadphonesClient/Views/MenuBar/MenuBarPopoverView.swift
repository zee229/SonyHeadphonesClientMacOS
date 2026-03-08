import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject var manager: HeadphonesManager
    @StateObject private var nowPlaying = NowPlayingMonitor()
    @AppStorage("menuBarShowBatterySection") private var showBattery: Bool = true
    @AppStorage("menuBarShowNCSection") private var showNC: Bool = true
    @AppStorage("menuBarShowPlaybackSection") private var showPlayback: Bool = true
    @AppStorage("menuBarShowVolumeControl") private var showVolume: Bool = true

    private var trackTitle: String {
        !manager.playTrackTitle.isEmpty ? manager.playTrackTitle : nowPlaying.title
    }
    private var trackArtist: String {
        !manager.playTrackArtist.isEmpty ? manager.playTrackArtist : nowPlaying.artist
    }

    private var isConnected: Bool {
        manager.connectionState == .connected
    }

    private var isReconnecting: Bool {
        if case .reconnecting = manager.connectionState { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            if isConnected {
                connectedContent
            } else {
                disconnectedContent
            }

            Divider()
            footerButtons
        }
        .frame(width: 300)
        .onAppear { if isConnected { nowPlaying.start() } }
        .onDisappear { nowPlaying.stop() }
        .onChange(of: isConnected) { _, connected in
            if connected { nowPlaying.start() } else { nowPlaying.stop() }
        }
    }

    // MARK: - Connected

    @ViewBuilder
    private var connectedContent: some View {
        // Device header
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "headphones")
                    .foregroundColor(.accentColor)
                Text(manager.modelName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if manager.supports(.codecIndicator) {
                        BadgeView(text: manager.audioCodec.displayName)
                    }
                    if manager.upscalingEnabled {
                        BadgeView(text: manager.upscalingType.displayName)
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)

        // Battery
        if showBattery {
            batterySection
        }

        // NC/Ambient mode
        if showNC {
            if showBattery { Divider().padding(.vertical, 4) }
            ncSection
        }

        // Playback
        if showPlayback {
            if showBattery || showNC { Divider().padding(.vertical, 4) }
            playbackSection
        }
    }

    // MARK: - Battery

    @ViewBuilder
    private var batterySection: some View {
        let supportSingle = manager.supports(.batteryLevelIndicator) || manager.supports(.batteryLevelWithThreshold)
        let supportLR = manager.supports(.leftRightBatteryLevelIndicator) || manager.supports(.lrBatteryLevelWithThreshold)
        let supportCase = manager.supports(.cradleBatteryLevelIndicator) || manager.supports(.cradleBatteryLevelWithThreshold)

        VStack(alignment: .leading, spacing: 3) {
            if supportSingle && !supportLR && manager.batteryL.threshold > 0 {
                MenuBarBatteryRow(label: "Battery", battery: manager.batteryL)
            }
            if supportLR {
                if manager.batteryL.threshold > 0 {
                    MenuBarBatteryRow(label: "L", battery: manager.batteryL)
                }
                if manager.batteryR.threshold > 0 {
                    MenuBarBatteryRow(label: "R", battery: manager.batteryR)
                }
            }
            if supportCase && manager.batteryCase.threshold > 0 {
                MenuBarBatteryRow(label: "Case", battery: manager.batteryCase)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - NC/Ambient

    @ViewBuilder
    private var ncSection: some View {
        let supportNC = manager.supports(.noiseCancellingOnOff)
            || manager.supports(.noiseCancellingOnOffAndASMOnOff)
            || manager.supports(.ncDualSingleOffAndASMOnOff)
            || manager.supports(.ncOnOffAndASMLevelAdj)
            || manager.supports(.ncDualSingleOffASMLevelAdj)
            || manager.supports(.modeNcAsmDualAutoASMLevelAdj)
            || manager.supports(.modeNcAsmDualSingleASMLevelAdj)
            || manager.supports(.modeNcAsmDualASMLevelAdj)
            || manager.supports(.modeNcNcssAsmDualASMLevelAdjWithTestMode)
            || manager.supports(.modeNcAsmDualASMLevelAdjNoiseAdaptation)

        let supportASM = manager.supports(.noiseCancellingOnOffAndASMOnOff)
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

        if supportNC || supportASM {
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    if supportNC {
                        MenuBarModePill(
                            title: "NC",
                            icon: "minus.circle",
                            isSelected: manager.ncAsmEnabled && (!supportASM || manager.ncAsmMode == .nc)
                        ) {
                            manager.ncAsmEnabled = true
                            manager.ncAsmMode = .nc
                        }
                    }
                    if supportASM {
                        MenuBarModePill(
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
                    MenuBarModePill(
                        title: "Off",
                        icon: "power",
                        isSelected: !manager.ncAsmEnabled
                    ) {
                        manager.ncAsmEnabled = false
                    }
                }

                if supportASM && manager.ncAsmEnabled && manager.ncAsmMode == .asm_ {
                    HStack(spacing: 6) {
                        Text("Level")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(manager.ncAsmAmbientLevel) },
                                set: { manager.ncAsmAmbientLevel = Int32($0) }
                            ),
                            in: 1...20,
                            step: 1
                        )
                        Text("\(manager.ncAsmAmbientLevel)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .frame(width: 20, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Playback

    private var useAppleScriptControls: Bool {
        manager.playTrackTitle.isEmpty && nowPlaying.selectedSource != nil
    }

    private var menuBarIsPlaying: Bool {
        if useAppleScriptControls {
            return nowPlaying.selectedSource?.isPlaying ?? false
        }
        return manager.playPause == .play
    }

    @ViewBuilder
    private var playbackSection: some View {
        VStack(spacing: 6) {
            if !trackTitle.isEmpty {
                VStack(spacing: 1) {
                    Text(trackTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !trackArtist.isEmpty {
                        Text(trackArtist)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if nowPlaying.hasMultipleSources {
                HStack(spacing: 4) {
                    ForEach(nowPlaying.sources) { src in
                        MenuBarSourcePill(
                            source: src,
                            isSelected: nowPlaying.selectedSourceId == src.id
                        ) {
                            nowPlaying.selectedSourceId = src.id
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                Button {
                    if useAppleScriptControls, let id = nowPlaying.selectedSourceId {
                        nowPlaying.sendPreviousTrack(for: id)
                    } else {
                        manager.sendPlaybackControl(.trackDown)
                    }
                } label: {
                    Image(systemName: "backward.fill").font(.caption)
                }
                .buttonStyle(.plain)

                Button {
                    if useAppleScriptControls, let id = nowPlaying.selectedSourceId {
                        nowPlaying.sendPlayPause(for: id)
                    } else if manager.playPause == .play {
                        manager.sendPlaybackControl(.pause)
                    } else {
                        manager.sendPlaybackControl(.play)
                    }
                } label: {
                    Image(systemName: menuBarIsPlaying ? "pause.fill" : "play.fill")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Button {
                    if useAppleScriptControls, let id = nowPlaying.selectedSourceId {
                        nowPlaying.sendNextTrack(for: id)
                    } else {
                        manager.sendPlaybackControl(.trackUp)
                    }
                } label: {
                    Image(systemName: "forward.fill").font(.caption)
                }
                .buttonStyle(.plain)

                if showVolume {
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(manager.playVolume) },
                                set: { manager.playVolume = Int32($0) }
                            ),
                            in: 0...30,
                            step: 1
                        )
                        .frame(width: 70)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Disconnected

    @ViewBuilder
    private var disconnectedContent: some View {
        VStack(spacing: 8) {
            if isReconnecting {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundColor(.accentColor)
                Text("Reconnecting...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if case .reconnecting(let attempt, let maxAttempts, _) = manager.connectionState {
                    Text("Attempt \(attempt) of \(maxAttempts)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "headphones")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundColor(.secondary)
                Text("Not Connected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footerButtons: some View {
        HStack {
            Button("Open") {
                openMainWindow()
            }
            .font(.caption)

            Button {
                openSettingsWindow()
            } label: {
                Image(systemName: "gearshape")
                    .font(.caption)
            }

            Spacer()

            if isConnected {
                Button("Disconnect") {
                    manager.disconnect()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            } else if isReconnecting {
                Button("Cancel Reconnect") {
                    manager.cancelReconnect()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title.contains("Sony") || $0.contentView is NSHostingView<ContentView> }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            for window in NSApp.windows where !window.title.isEmpty && window.level == .normal {
                window.makeKeyAndOrderFront(nil)
                break
            }
        }
    }
}

// MARK: - Compact Components

struct MenuBarBatteryRow: View {
    let label: String
    let battery: BatteryInfo

    var body: some View {
        HStack(spacing: 4) {
            Text("\(label): \(battery.level)%")
                .font(.caption2)
                .frame(width: 70, alignment: .leading)
            ProgressView(value: Double(battery.level), total: 100)
                .tint(.green)
                .frame(maxWidth: .infinity)
            if !battery.charging.displayName.isEmpty {
                Text(battery.charging.displayName)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MenuBarModePill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(title)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.controlBackgroundColor))
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color(.separatorColor), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MenuBarSourcePill: View {
    let source: MediaSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: source.sfSymbol)
                    .font(.system(size: 9))
                Text(source.displayName)
                    .font(.caption2)
                if source.isPlaying {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.controlBackgroundColor))
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color(.separatorColor), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
