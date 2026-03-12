import SwiftUI

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

// MARK: - Playback Tab

struct PlaybackTab: View {
    @EnvironmentObject var manager: HeadphonesManager
    @ObservedObject private var nowPlaying = NowPlayingService.shared

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
        manager.playTrackTitle.isEmpty && nowPlaying.activeSource != nil
    }

    private var isPlaying: Bool {
        if useAppleScriptControls {
            return nowPlaying.isPlaying
        }
        return manager.playPause == .play
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
                            if useAppleScriptControls {
                                nowPlaying.sendPreviousTrack()
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
                            if useAppleScriptControls {
                                nowPlaying.sendPlayPause()
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
                            if useAppleScriptControls {
                                nowPlaying.sendNextTrack()
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
        .onAppear { NowPlayingService.shared.start() }
        .onDisappear { NowPlayingService.shared.stop() }
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

                if let source = nowPlaying.activeSource, manager.playTrackTitle.isEmpty {
                    Text(source.displayName)
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
