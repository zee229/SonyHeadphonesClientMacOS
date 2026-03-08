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
        let lower = id.lowercased()
        if lower.contains("spotify") { return "music.note.list" }
        if lower.contains("music") { return "music.quarternote.3" }
        if lower.contains("chrome") || lower.contains("safari") || lower.contains("firefox") || lower.contains("arc") { return "globe" }
        if lower.contains("vlc") || lower.contains("iina") { return "play.rectangle" }
        return "speaker.wave.2"
    }
}

// MARK: - Now Playing Monitor

#if !APPSTORE

// Full NowPlayingMonitor with MediaRemote + AppleScript + CGEvent (direct distribution)

@MainActor
class NowPlayingMonitor: ObservableObject {
    @Published var sources: [MediaSource] = []
    @Published var selectedSourceId: String?

    private var timer: Timer?

    // MediaRemote function pointers
    private static let mrBundle: CFBundle? = CFBundleCreate(kCFAllocatorDefault,
        NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

    private typealias MRGetInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRGetClientFn = @convention(c) (DispatchQueue, @escaping (AnyObject?) -> Void) -> Void

    private static let getInfo: MRGetInfoFn? = {
        guard let b = mrBundle, let p = CFBundleGetFunctionPointerForName(b, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return nil }
        return unsafeBitCast(p, to: MRGetInfoFn.self)
    }()

    private static let getClient: MRGetClientFn? = {
        guard let b = mrBundle, let p = CFBundleGetFunctionPointerForName(b, "MRMediaRemoteGetNowPlayingClient" as CFString) else { return nil }
        return unsafeBitCast(p, to: MRGetClientFn.self)
    }()

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
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        // Query MediaRemote for system now playing
        Self.getClient?(DispatchQueue.main) { [weak self] client in
            guard let self else { return }
            let bundleId = (client as? NSObject)?.value(forKey: "bundleIdentifier") as? String
            let appName = Self.appName(from: bundleId)

            Self.getInfo?(DispatchQueue.main) { [weak self] info in
                guard let self else { return }
                let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
                let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
                let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String ?? ""
                let rate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
                let isPlaying = rate > 0

                if !title.isEmpty || isPlaying {
                    let src = MediaSource(id: appName, title: title, artist: artist, album: album, isPlaying: isPlaying)
                    self.sources = [src]
                    self.selectedSourceId = src.id
                } else {
                    self.sources = []
                    self.selectedSourceId = nil
                }
            }
        }
    }

    private static func appName(from bundleId: String?) -> String {
        guard let bundleId else { return "Unknown" }
        // Try to get the display name from the running app
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first,
           let name = app.localizedName {
            return name
        }
        // Fallback: extract from bundle ID
        let last = bundleId.components(separatedBy: ".").last ?? bundleId
        return last.capitalized
    }

    // MARK: - Playback Controls

    func sendPlayPause(for sourceId: String) {
        if sourceId == "Spotify" {
            runAppleScript("tell application \"Spotify\" to playpause")
        } else if sourceId == "Apple Music" || sourceId == "Music" {
            runAppleScript("tell application \"Music\" to playpause")
        } else {
            simulateMediaKey(key: 16) // play/pause
        }
    }

    func sendNextTrack(for sourceId: String) {
        if sourceId == "Spotify" {
            runAppleScript("tell application \"Spotify\" to next track")
        } else if sourceId == "Apple Music" || sourceId == "Music" {
            runAppleScript("tell application \"Music\" to next track")
        } else {
            simulateMediaKey(key: 17) // next
        }
    }

    func sendPreviousTrack(for sourceId: String) {
        if sourceId == "Spotify" {
            runAppleScript("tell application \"Spotify\" to previous track")
        } else if sourceId == "Apple Music" || sourceId == "Music" {
            runAppleScript("tell application \"Music\" to back track")
        } else {
            simulateMediaKey(key: 18) // previous
        }
    }

    private func simulateMediaKey(key: UInt32) {
        func doKey(down: Bool) {
            let flags: NSEvent.EventType = down ? .systemDefined : .systemDefined
            let data1 = Int((key << 16) | (down ? 0x0A00 : 0x0B00))
            let event = NSEvent.otherEvent(
                with: flags,
                location: .zero,
                modifierFlags: NSEvent.ModifierFlags(rawValue: (down ? 0xa00 : 0xb00)),
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            event?.cgEvent?.post(tap: .cghidEventTap)
        }
        doKey(down: true)
        doKey(down: false)
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

#else

// Stub NowPlayingMonitor for App Store — AVRCP only, no MediaRemote/AppleScript/CGEvent

@MainActor
class NowPlayingMonitor: ObservableObject {
    @Published var sources: [MediaSource] = []
    @Published var selectedSourceId: String?

    var title: String { "" }
    var artist: String { "" }
    var album: String { "" }
    var source: String { "" }

    var selectedSource: MediaSource? { nil }
    var hasMultipleSources: Bool { false }

    func start() {}
    func stop() {}

    func sendPlayPause(for sourceId: String) {}
    func sendNextTrack(for sourceId: String) {}
    func sendPreviousTrack(for sourceId: String) {}
}

#endif

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
                    .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.controlBackgroundColor))
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color(.separatorColor), lineWidth: 0.5)
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
