import SwiftUI

// MARK: - Media Source

struct MediaSource: Identifiable, Equatable {
    let id: String
    var title: String
    var artist: String
    var album: String
    var isPlaying: Bool

    var displayName: String {
        id == "Music" ? "Apple Music" : id
    }

    var sfSymbol: String {
        id == "Spotify" ? "music.note.list" : "music.quarternote.3"
    }
}

// MARK: - Now Playing Monitor (AppleScript-based)

@MainActor
class NowPlayingMonitor: ObservableObject {
    @Published var sources: [MediaSource] = []
    @Published var selectedSourceId: String?

    private var timer: Timer?

    // Backward-compatible computed properties from selected source
    var title: String { selectedSource?.title ?? "" }
    var artist: String { selectedSource?.artist ?? "" }
    var album: String { selectedSource?.album ?? "" }
    var source: String { selectedSource?.displayName ?? "" }

    var selectedSource: MediaSource? {
        guard let id = selectedSourceId else { return sources.first }
        return sources.first(where: { $0.id == id }) ?? sources.first
    }

    var hasMultipleSources: Bool { sources.count > 1 }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        Task.detached {
            let newSources = Self.queryAllSources()
            await MainActor.run {
                self.sources = newSources
                // Auto-select logic
                if newSources.isEmpty {
                    self.selectedSourceId = nil
                } else if newSources.count == 1 {
                    self.selectedSourceId = newSources[0].id
                } else if let selected = self.selectedSourceId,
                          !newSources.contains(where: { $0.id == selected }) {
                    self.selectedSourceId = newSources.first?.id
                }
            }
        }
    }

    private nonisolated static func queryAllSources() -> [MediaSource] {
        let script = """
        set output to ""
        try
            if application "Spotify" is running then
                tell application "Spotify"
                    set pState to "paused"
                    if player state is playing then set pState to "playing"
                    set output to output & "Spotify" & "\\n" & pState & "\\n" & (name of current track) & "\\n" & (artist of current track) & "\\n" & (album of current track) & "\\n---\\n"
                end tell
            end if
        end try
        try
            if application "Music" is running then
                tell application "Music"
                    set pState to "paused"
                    if player state is playing then set pState to "playing"
                    set output to output & "Music" & "\\n" & pState & "\\n" & (name of current track) & "\\n" & (artist of current track) & "\\n" & (album of current track) & "\\n---\\n"
                end tell
            end if
        end try
        return output
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        var results: [MediaSource] = []
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let blocks = output.components(separatedBy: "---")
            for block in blocks {
                let lines = block.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
                if lines.count >= 5 {
                    results.append(MediaSource(
                        id: lines[0],
                        title: lines[2],
                        artist: lines[3],
                        album: lines[4],
                        isPlaying: lines[1] == "playing"
                    ))
                }
            }
        } catch {}

        return results
    }

    // MARK: - AppleScript Playback Controls

    func sendPlayPause(for sourceId: String) {
        let cmd: String
        if sourceId == "Spotify" {
            cmd = "tell application \"Spotify\" to playpause"
        } else {
            cmd = "tell application \"Music\" to playpause"
        }
        runAppleScript(cmd)
    }

    func sendNextTrack(for sourceId: String) {
        let cmd: String
        if sourceId == "Spotify" {
            cmd = "tell application \"Spotify\" to next track"
        } else {
            cmd = "tell application \"Music\" to next track"
        }
        runAppleScript(cmd)
    }

    func sendPreviousTrack(for sourceId: String) {
        let cmd: String
        if sourceId == "Spotify" {
            cmd = "tell application \"Spotify\" to previous track"
        } else {
            cmd = "tell application \"Music\" to back track"
        }
        runAppleScript(cmd)
    }

    private func runAppleScript(_ script: String) {
        Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
        }
    }
}

// MARK: - Play Button Modifier

struct PlayButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .foregroundColor(.accentColor)
        } else {
            content
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Audio Visualizer

struct AudioVisualizerView: View {
    let isPlaying: Bool
    private let barCount = 9

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !isPlaying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    let h = isPlaying ? barHeight(for: index, at: time) : 0.05

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.accentColor.opacity(0.3), .accentColor],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 3, height: 3 + h * 37)
                }
            }
            .frame(height: 40)
        }
    }

    private func barHeight(for index: Int, at time: TimeInterval) -> CGFloat {
        let f1: [Double] = [1.3, 1.8, 1.0, 2.1, 0.9, 1.6, 1.2, 1.7, 1.1]
        let f2: [Double] = [2.7, 2.2, 3.1, 1.5, 2.9, 2.4, 2.0, 2.6, 3.3]
        let shape: [Double] = [0.5, 0.7, 0.85, 0.95, 1.0, 0.95, 0.85, 0.7, 0.5]
        let phase = Double(index) * 0.618

        let v1 = sin(time * f1[index] * .pi + phase)
        let v2 = sin(time * f2[index] * .pi + phase * 1.3)
        let v3 = sin(time * 0.4 * .pi + phase * 0.5)

        let combined = ((v1 * 0.5 + v2 * 0.3 + v3 * 0.2 + 1) / 2) * shape[index]
        return CGFloat(max(0.05, min(1.0, combined)))
    }
}

// MARK: - Source Pill

struct SourcePill: View {
    let source: MediaSource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if #available(macOS 26, *) {
            Button(action: action) {
                pillContent
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
            )
        } else {
            Button(action: action) {
                pillContent
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color(nsColor: .separatorColor), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var pillContent: some View {
        HStack(spacing: 5) {
            Image(systemName: source.sfSymbol)
                .font(.caption)
            Text(source.displayName)
                .font(.subheadline)
            if source.isPlaying {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// MARK: - Playback Tab

struct PlaybackTab: View {
    @EnvironmentObject var manager: HeadphonesManager
    @StateObject private var nowPlaying = NowPlayingMonitor()

    // Use headphones AVRCP data if available, otherwise system query
    private var trackTitle: String {
        !manager.playTrackTitle.isEmpty ? manager.playTrackTitle : nowPlaying.title
    }
    private var trackArtist: String {
        !manager.playTrackArtist.isEmpty ? manager.playTrackArtist : nowPlaying.artist
    }
    private var trackAlbum: String {
        !manager.playTrackAlbum.isEmpty ? manager.playTrackAlbum : nowPlaying.album
    }

    private var useAppleScriptControls: Bool {
        manager.playTrackTitle.isEmpty && nowPlaying.selectedSource != nil
    }

    private var isPlaying: Bool {
        if useAppleScriptControls {
            return nowPlaying.selectedSource?.isPlaying ?? false
        }
        return manager.playPause == .play
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Now Playing
                nowPlayingSection

                // Source picker (only when 2+ sources)
                if nowPlaying.hasMultipleSources {
                    HStack(spacing: 8) {
                        ForEach(nowPlaying.sources) { src in
                            SourcePill(
                                source: src,
                                isSelected: nowPlaying.selectedSourceId == src.id
                            ) {
                                nowPlaying.selectedSourceId = src.id
                            }
                        }
                    }
                }

                // Controls
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        Button {
                            if useAppleScriptControls, let id = nowPlaying.selectedSourceId {
                                nowPlaying.sendPreviousTrack(for: id)
                            } else {
                                manager.sendPlaybackControl(.trackDown)
                            }
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        Button {
                            if useAppleScriptControls, let id = nowPlaying.selectedSourceId {
                                nowPlaying.sendPlayPause(for: id)
                            } else if manager.playPause == .play {
                                manager.sendPlaybackControl(.pause)
                            } else {
                                manager.sendPlaybackControl(.play)
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 48))
                        }
                        .modifier(PlayButtonModifier())

                        Button {
                            if useAppleScriptControls, let id = nowPlaying.selectedSourceId {
                                nowPlaying.sendNextTrack(for: id)
                            } else {
                                manager.sendPlaybackControl(.trackUp)
                            }
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Volume
                VStack(spacing: 6) {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        Slider(
                            value: Binding(
                                get: { Double(manager.playVolume) },
                                set: { manager.playVolume = Int32($0) }
                            ),
                            in: 0...30,
                            step: 1
                        )
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                    }
                    Text("\(manager.playVolume)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .onAppear { nowPlaying.start() }
        .onDisappear { nowPlaying.stop() }
    }

    @ViewBuilder
    private var nowPlayingSection: some View {
        let hasTrack = !trackTitle.isEmpty

        VStack(spacing: 8) {
            if isPlaying {
                AudioVisualizerView(isPlaying: true)
            } else if hasTrack {
                Image(systemName: "music.note")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(.accentColor)
            } else {
                Image(systemName: "music.note.slash")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(.secondary)
            }

            if hasTrack {
                Text(trackTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if !trackArtist.isEmpty || !trackAlbum.isEmpty {
                    VStack(spacing: 2) {
                        if !trackArtist.isEmpty {
                            Text(trackArtist)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        if !trackAlbum.isEmpty {
                            Text(trackAlbum)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                if !nowPlaying.source.isEmpty && manager.playTrackTitle.isEmpty && !nowPlaying.hasMultipleSources {
                    Text(nowPlaying.source)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if isPlaying {
                Text("Audio Playing")
                    .font(.headline)

                Text("Source not recognized")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Not Playing")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
