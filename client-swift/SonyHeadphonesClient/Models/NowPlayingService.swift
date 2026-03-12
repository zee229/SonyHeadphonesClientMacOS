import Foundation
import AppKit

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

// MARK: - Now Playing Service (AppleScript-based)

@MainActor
final class NowPlayingService: ObservableObject {
    static let shared = NowPlayingService()

    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var isPlaying: Bool = false
    @Published var activeSource: MediaSource?

    private var timer: Timer?
    private var refCount = 0

    private init() {}

    // MARK: - Lifecycle (ref-counted start/stop)

    func start() {
        refCount += 1
        guard refCount == 1 else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        refCount -= 1
        guard refCount <= 0 else { return }
        refCount = 0
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Playback Controls

    func sendPlayPause() {
        guard let source = activeSource else {
            simulateMediaKey(key: 16)
            return
        }
        if source.id == "Spotify" {
            runAppleScript("tell application \"Spotify\" to playpause")
        } else if source.id == "Music" {
            runAppleScript("tell application \"Music\" to playpause")
        } else {
            simulateMediaKey(key: 16)
        }
    }

    func sendNextTrack() {
        guard let source = activeSource else {
            simulateMediaKey(key: 17)
            return
        }
        if source.id == "Spotify" {
            runAppleScript("tell application \"Spotify\" to next track")
        } else if source.id == "Music" {
            runAppleScript("tell application \"Music\" to next track")
        } else {
            simulateMediaKey(key: 17)
        }
    }

    func sendPreviousTrack() {
        guard let source = activeSource else {
            simulateMediaKey(key: 18)
            return
        }
        if source.id == "Spotify" {
            runAppleScript("tell application \"Spotify\" to previous track")
        } else if source.id == "Music" {
            runAppleScript("tell application \"Music\" to back track")
        } else {
            simulateMediaKey(key: 18)
        }
    }

    // MARK: - Private

    private func refresh() {
        // Try Spotify first, then Apple Music
        if isAppRunning(bundleId: "com.spotify.client") {
            querySpotify()
        } else if isAppRunning(bundleId: "com.apple.Music") {
            queryAppleMusic()
        } else {
            clearState()
        }
    }

    private func querySpotify() {
        let script = """
        tell application "Spotify"
            if player state is playing then
                set t to name of current track
                set a to artist of current track
                set al to album of current track
                return "playing" & "\n" & t & "\n" & a & "\n" & al
            else if player state is paused then
                set t to name of current track
                set a to artist of current track
                set al to album of current track
                return "paused" & "\n" & t & "\n" & a & "\n" & al
            else
                return "stopped"
            end if
        end tell
        """
        runQuery(script: script, sourceId: "Spotify")
    }

    private func queryAppleMusic() {
        let script = """
        tell application "Music"
            if player state is playing then
                set t to name of current track
                set a to artist of current track
                set al to album of current track
                return "playing" & "\n" & t & "\n" & a & "\n" & al
            else if player state is paused then
                set t to name of current track
                set a to artist of current track
                set al to album of current track
                return "paused" & "\n" & t & "\n" & a & "\n" & al
            else
                return "stopped"
            end if
        end tell
        """
        runQuery(script: script, sourceId: "Music")
    }

    private func runQuery(script: String, sourceId: String) {
        Task {
            let output = await Self.executeOsascript(script)
            let lines = output.components(separatedBy: "\n")
            guard lines.count >= 1 else {
                clearState()
                return
            }

            let state = lines[0]
            if state == "stopped" || lines.count < 4 {
                if state == "stopped" {
                    title = ""
                    artist = ""
                    album = ""
                    isPlaying = false
                    activeSource = nil
                } else {
                    clearState()
                }
                return
            }

            let playing = state == "playing"
            title = lines[1]
            artist = lines[2]
            album = lines[3]
            isPlaying = playing
            activeSource = MediaSource(
                id: sourceId,
                title: lines[1],
                artist: lines[2],
                album: lines[3],
                isPlaying: playing
            )
        }
    }

    private static func executeOsascript(_ script: String) async -> String {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()
                } catch {
                    continuation.resume(returning: "")
                    return
                }

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                continuation.resume(returning: output)
            }
        }
    }

    private func clearState() {
        title = ""
        artist = ""
        album = ""
        isPlaying = false
        activeSource = nil
    }

    private func isAppRunning(bundleId: String) -> Bool {
        !NSWorkspace.shared.runningApplications.filter({ $0.bundleIdentifier == bundleId }).isEmpty
    }

    private func simulateMediaKey(key: UInt32) {
        func doKey(down: Bool) {
            let data1 = Int((key << 16) | (down ? 0x0A00 : 0x0B00))
            let event = NSEvent.otherEvent(
                with: .systemDefined,
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
