import SwiftUI

struct PlaybackTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Now Playing area
                VStack(spacing: 16) {
                    Image(systemName: manager.playPause == .play ? "music.note" : "pause.circle")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.accentColor)
                        .frame(height: 56)

                    // Controls
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
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)

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
    }
}
