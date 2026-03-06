import SwiftUI

struct DisconnectedView: View {
    @EnvironmentObject var manager: HeadphonesManager
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Device Disconnected")
                .font(.title2)
                .fontWeight(.medium)

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            if !message.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(.horizontal)
            }

            Button {
                manager.disconnect()
            } label: {
                Label("Reconnect", systemImage: "link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}
