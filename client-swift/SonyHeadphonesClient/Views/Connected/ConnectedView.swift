import SwiftUI

struct ConnectedView: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider()
            TabView {
                PlaybackTab()
                    .tabItem { Label("Playback", systemImage: "play.circle") }
                SoundTab()
                    .tabItem { Label("Sound", systemImage: "waveform") }
                DevicesTab()
                    .tabItem { Label("Devices", systemImage: "airpodspro") }
                SystemTab()
                    .tabItem { Label("System", systemImage: "gearshape") }
                AboutTab()
                    .tabItem { Label("About", systemImage: "info.circle") }
            }
        }
    }
}
