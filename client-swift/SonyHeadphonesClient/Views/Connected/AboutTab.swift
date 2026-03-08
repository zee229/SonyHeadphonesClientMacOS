import SwiftUI
import CoreBluetooth
import ServiceManagement

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
                AppSettingsView(manager: manager)

                // App info
                VStack(spacing: 4) {
                    Text("SoundPilot")
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
    var manager: HeadphonesManager?

    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("alwaysOnTop") private var alwaysOnTop: Bool = false
    @AppStorage("menuBarEnabled") private var menuBarEnabled: Bool = true
    @AppStorage("menuBarIconStyle") private var menuBarIconStyle: Int = 1
    @AppStorage("menuBarShowBatterySection") private var showBattery: Bool = true
    @AppStorage("menuBarShowNCSection") private var showNC: Bool = true
    @AppStorage("menuBarShowPlaybackSection") private var showPlayback: Bool = true
    @AppStorage("menuBarShowVolumeControl") private var showVolume: Bool = true

    private var rememberedDeviceName: String? {
        UserDefaults.standard.string(forKey: "rememberedDeviceName")
    }

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

            #if !APPSTORE
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
            #endif

            // Connection
            SoundCard {
                Label("Connection", systemImage: "link")
                    .font(.headline)

                if let name = rememberedDeviceName {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Remembered Device")
                                .font(.subheadline)
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Forget") {
                            if let mgr = manager {
                                mgr.forgetRememberedDevice()
                            } else {
                                UserDefaults.standard.removeObject(forKey: "rememberedDeviceMac")
                                UserDefaults.standard.removeObject(forKey: "rememberedDeviceName")
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                } else {
                    HStack {
                        Text("No remembered device")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }

            // Menu Bar
            SoundCard {
                Label("Menu Bar", systemImage: "menubar.rectangle")
                    .font(.headline)

                HStack {
                    Text("Show in Menu Bar")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $menuBarEnabled)
                        .labelsHidden()
                }

                if menuBarEnabled {
                    Divider()

                    Picker("Icon Style", selection: $menuBarIconStyle) {
                        Text("Icon Only").tag(0)
                        Text("Icon + Battery").tag(1)
                        Text("Battery Only").tag(2)
                    }
                    .font(.subheadline)

                    Divider()

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Popover Sections")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Battery")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $showBattery)
                            .labelsHidden()
                    }

                    HStack {
                        Text("Sound Mode")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $showNC)
                            .labelsHidden()
                    }

                    HStack {
                        Text("Playback")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $showPlayback)
                            .labelsHidden()
                    }

                    HStack {
                        Text("Volume")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: $showVolume)
                            .labelsHidden()
                    }

                    Divider()

                    HStack {
                        Text("Launch at Login")
                            .font(.subheadline)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { SMAppService.mainApp.status == .enabled },
                            set: { newValue in
                                if newValue {
                                    try? SMAppService.mainApp.register()
                                } else {
                                    try? SMAppService.mainApp.unregister()
                                }
                            }
                        ))
                        .labelsHidden()
                    }
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
                        openPrivacySettings("Privacy_Bluetooth")
                    } label: {
                        Label("Grant in System Settings", systemImage: "arrow.up.forward.app")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                #if !APPSTORE
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Automation")
                            .font(.subheadline)
                        Text("Required for Now Playing info (Spotify, Music)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        openPrivacySettings("Privacy_Automation")
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Open Automation settings")
                }
                #endif
            }
        }
        #if !APPSTORE
        .onAppear {
            setWindowLevel(alwaysOnTop: alwaysOnTop)
        }
        #endif
    }

    private func openPrivacySettings(_ section: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(section)") {
            NSWorkspace.shared.open(url)
        }
    }

    #if !APPSTORE
    private func setWindowLevel(alwaysOnTop: Bool) {
        DispatchQueue.main.async {
            for window in NSApplication.shared.windows {
                if window.isVisible && window.title != "Settings" {
                    window.level = alwaysOnTop ? .floating : .normal
                }
            }
        }
    }
    #endif
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
