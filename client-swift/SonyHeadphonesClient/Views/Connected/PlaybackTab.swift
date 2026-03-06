import SwiftUI

struct PlaybackTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Volume
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volume")
                            .font(.headline)
                        Slider(
                            value: Binding(
                                get: { Double(manager.playVolume) },
                                set: { manager.playVolume = Int32($0) }
                            ),
                            in: 0...30,
                            step: 1
                        )
                        Text("\(manager.playVolume)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Controls
                Section {
                    Text("Controls")
                        .font(.headline)
                    HStack(spacing: 12) {
                        Button {
                            manager.sendPlaybackControl(.trackDown)
                        } label: {
                            Image(systemName: "backward.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            if manager.playPause == .play {
                                manager.sendPlaybackControl(.pause)
                            } else {
                                manager.sendPlaybackControl(.play)
                            }
                        } label: {
                            Image(systemName: manager.playPause == .play ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            manager.sendPlaybackControl(.trackUp)
                        } label: {
                            Image(systemName: "forward.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
        }
    }
}
