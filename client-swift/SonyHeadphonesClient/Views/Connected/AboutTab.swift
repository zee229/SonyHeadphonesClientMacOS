import SwiftUI
import CoreBluetooth

struct AboutTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Device hero
                VStack(spacing: 8) {
                    Image(systemName: "headphones")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.accentColor)

                    Text(manager.modelName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if !manager.fwVersion.isEmpty {
                        Text("Firmware \(manager.fwVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Info card
                SoundCard {
                    InfoRow(icon: "number", label: "MAC Address", value: manager.uniqueId)
                    Divider()
                    InfoRow(icon: "square.stack.3d.up", label: "Series", value: manager.modelSeries.displayName)
                    Divider()
                    InfoRow(icon: "paintpalette", label: "Color", value: manager.modelColor.displayName)
                }

                // Settings
                AppSettingsView()

                // App info
                VStack(spacing: 4) {
                    Text("Sony Headphones Client")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("v2.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct AppSettingsView: View {
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false

    private var bluetoothStatus: (String, Color) {
        switch CBCentralManager.authorization {
        case .allowedAlways:
            return ("Granted", .green)
        case .denied:
            return ("Denied", .red)
        case .restricted:
            return ("Restricted", .orange)
        case .notDetermined:
            return ("Not Determined", .secondary)
        @unknown default:
            return ("Unknown", .secondary)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Appearance
            SoundCard {
                Label("Appearance", systemImage: "paintbrush")
                    .font(.headline)

                Picker("Theme", selection: $appTheme) {
                    ForEach(AppTheme.allCases, id: \.rawValue) {
                        Text($0.displayName).tag($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Window
            SoundCard {
                Label("Window", systemImage: "macwindow")
                    .font(.headline)

                HStack {
                    Text("Always on Top")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $alwaysOnTop)
                        .labelsHidden()
                }
                .onChange(of: alwaysOnTop) { _, newValue in
                    setWindowLevel(alwaysOnTop: newValue)
                }
            }

            // Permissions
            SoundCard {
                Label("Permissions", systemImage: "lock.shield")
                    .font(.headline)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bluetooth Access")
                            .font(.subheadline)
                        Text("Required for connecting to headphones")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(bluetoothStatus.0)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(bluetoothStatus.1)
                }

                if CBCentralManager.authorization != .allowedAlways {
                    Button {
                        openPrivacySettings()
                    } label: {
                        Label("Grant in System Settings", systemImage: "arrow.up.forward.app")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .onAppear {
            setWindowLevel(alwaysOnTop: alwaysOnTop)
        }
    }

    private func openPrivacySettings() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"]
        try? process.run()
    }

    private func setWindowLevel(alwaysOnTop: Bool) {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                if window.isVisible && window.title != "Settings" {
                    window.level = alwaysOnTop ? .floating : .normal
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}
