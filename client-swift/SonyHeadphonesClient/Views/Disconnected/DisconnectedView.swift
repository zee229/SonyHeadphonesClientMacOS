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

            VStack(spacing: 10) {
                Button {
                    manager.reconnectToLastDevice()
                } label: {
                    Label("Reconnect", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    manager.disconnect()
                } label: {
                    Label("Back to Devices", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}
