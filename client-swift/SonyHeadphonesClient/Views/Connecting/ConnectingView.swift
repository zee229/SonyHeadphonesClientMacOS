import SwiftUI

struct ConnectingView: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Connecting...")
                .font(.title2)

            ProgressView()
                .controlSize(.large)

            if !manager.connectionErrorMessage.isEmpty {
                Text(manager.connectionErrorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                manager.disconnect()
            } label: {
                Label("Cancel", systemImage: "xmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}
