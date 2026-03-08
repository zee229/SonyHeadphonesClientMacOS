import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        Group {
            switch manager.connectionState {
            case .disconnected:
                DiscoveryView()
            case .discovering:
                DiscoveryView()
            case .connecting:
                ConnectingView()
            case .connected:
                ConnectedView()
            case .reconnecting(let attempt, let maxAttempts, let deviceName):
                ReconnectingView(attempt: attempt, maxAttempts: maxAttempts, deviceName: deviceName)
            case .error(let message):
                DisconnectedView(message: message)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Remember Device?", isPresented: $manager.showRememberDeviceAlert) {
            Button("Remember") {
                manager.rememberCurrentDevice()
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Auto-connect to \(manager.modelName) on launch?")
        }
    }
}
