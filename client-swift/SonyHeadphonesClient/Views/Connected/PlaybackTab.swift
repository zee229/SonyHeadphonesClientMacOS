import SwiftUI

// MARK: - Now Playing Monitor (AppleScript-based)

@MainActor
class NowPlayingMonitor: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var source: String = ""

    private var timer: Timer?

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
            let result = Self.queryNowPlaying()
            await MainActor.run {
                if self.title != result.title { self.title = result.title }
                if self.artist != result.artist { self.artist = result.artist }
                if self.album != result.album { self.album = result.album }
                if self.source != result.source { self.source = result.source }
            }
        }
    }

    private nonisolated static func queryNowPlaying() -> (title: String, artist: String, album: String, source: String) {
        // Try Spotify first, then Music
        let script = """
        try
            if application "Spotify" is running then
                tell application "Spotify"
                    if player state is playing then
                        return "Spotify" & "\\n" & (name of current track) & "\\n" & (artist of current track) & "\\n" & (album of current track)
                    end if
                end tell
            end if
        end try
        try
            if application "Music" is running then
                tell application "Music"
                    if player state is playing then
                        return "Music" & "\\n" & (name of current track) & "\\n" & (artist of current track) & "\\n" & (album of current track)
                    end if
                end tell
            end if
        end try
        return ""
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let parts = output.components(separatedBy: "\n")
            if parts.count >= 4 {
                return (parts[1], parts[2], parts[3], parts[0])
            }
        } catch {}

        return ("", "", "", "")
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

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Now Playing
                nowPlayingSection

                // Controls
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        Button {
                            manager.sendPlaybackControl(.trackDown)
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        Button {
                            if manager.playPause == .play {
                                manager.sendPlaybackControl(.pause)
                            } else {
                                manager.sendPlaybackControl(.play)
                            }
                        } label: {
                            Image(systemName: manager.playPause == .play ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 48))
                        }
                        .modifier(PlayButtonModifier())

                        Button {
                            manager.sendPlaybackControl(.trackUp)
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
            Image(systemName: hasTrack ? "music.note" : "music.note.slash")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(hasTrack ? .accentColor : .secondary)

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

                if !nowPlaying.source.isEmpty && manager.playTrackTitle.isEmpty {
                    Text(nowPlaying.source)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
