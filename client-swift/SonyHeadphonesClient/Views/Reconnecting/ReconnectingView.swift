import SwiftUI

struct ReconnectingView: View {
    @EnvironmentObject var manager: HeadphonesManager
    let attempt: Int
    let maxAttempts: Int
    let deviceName: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Reconnecting...")
                .font(.title2)
                .fontWeight(.medium)

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear { isAnimating = true }

            if !deviceName.isEmpty {
                Text(deviceName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            Text("Attempt \(attempt) of \(maxAttempts)")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                manager.cancelReconnect()
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
