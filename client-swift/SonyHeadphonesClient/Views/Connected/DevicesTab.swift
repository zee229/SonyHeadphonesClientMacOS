import SwiftUI

struct DevicesTab: View {
    @EnvironmentObject var manager: HeadphonesManager
    @State private var expandedMac: String?

    private var supportDeviceMgmt: Bool {
        manager.supports(.pairingDeviceManagementClassicBT)
        || manager.supports(.pairingDeviceManagementWithBTClassOfDeviceClassicBT)
        || manager.supports(.pairingDeviceManagementWithBTClassOfDeviceClassicLE)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !supportDeviceMgmt {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.yellow)
                        Text("Enable \"Connect to 2 devices simultaneously\" in System settings to manage devices.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.yellow.opacity(0.08))
                    .cornerRadius(8)
                }

                let connected = manager.pairedDevices.filter(\.connected)
                let paired = manager.pairedDevices.filter { !$0.connected }

                if !connected.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Connected", systemImage: "link")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ForEach(connected) { device in
                            DeviceCard(
                                device: device,
                                isExpanded: expandedMac == device.id,
                                isMultipoint: device.id == manager.multipointDeviceMac,
                                onTap: { toggleExpanded(device.id) },
                                onDisconnect: { manager.disconnectPairedDevice(device.id) },
                                onConnect: nil,
                                onUnpair: { manager.unpairDevice(device.id) },
                                onSetMultipoint: { manager.setMultipointDeviceMac(device.id) }
                            )
                        }
                    }
                }

                if !paired.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Paired", systemImage: "dot.radiowaves.right")
                            .font(.headline)
                            .foregroundColor(.primary)

                        ForEach(paired) { device in
                            DeviceCard(
                                device: device,
                                isExpanded: expandedMac == device.id,
                                isMultipoint: false,
                                onTap: { toggleExpanded(device.id) },
                                onDisconnect: nil,
                                onConnect: { manager.connectPairedDevice(device.id) },
                                onUnpair: { manager.unpairDevice(device.id) },
                                onSetMultipoint: nil
                            )
                        }
                    }
                }

                if connected.isEmpty && paired.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "laptopcomputer.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No paired devices")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }

                // Pairing Mode
                VStack(spacing: 8) {
                    if manager.pairingMode {
                        HStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching for devices...")
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Stop") {
                                manager.pairingMode = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(12)
                        .background(Color.accentColor.opacity(0.08))
                        .cornerRadius(8)
                    } else {
                        Button {
                            manager.pairingMode = true
                        } label: {
                            Label("Enter Pairing Mode", systemImage: "antenna.radiowaves.left.and.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("For TWS (Earbuds) devices, you may need to take both of your headphones out from your case to enter Pairing Mode.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .disabled(!supportDeviceMgmt)
        }
    }

    private func toggleExpanded(_ mac: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            expandedMac = expandedMac == mac ? nil : mac
        }
    }
}

private func deviceIcon(for name: String) -> String {
    let lower = name.lowercased()
    if lower.contains("iphone") { return "iphone" }
    if lower.contains("ipad") { return "ipad" }
    if lower.contains("macbook") { return "laptopcomputer" }
    if lower.contains("mac") { return "desktopcomputer" }
    if lower.contains("apple") { return "apple.logo" }
    if lower.contains("watch") { return "applewatch" }
    if lower.contains("tv") { return "appletv" }
    return "desktopcomputer"
}

struct DeviceCard: View {
    let device: PairedDevice
    let isExpanded: Bool
    let isMultipoint: Bool
    let onTap: () -> Void
    let onDisconnect: (() -> Void)?
    let onConnect: (() -> Void)?
    let onUnpair: () -> Void
    let onSetMultipoint: (() -> Void)?

    @State private var pendingAction: String?

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: deviceIcon(for: device.name))
                        .font(.system(size: 20))
                        .foregroundColor(device.connected ? .accentColor : .secondary)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        HStack(spacing: 6) {
                            if pendingAction != nil {
                                ProgressView()
                                    .controlSize(.mini)
                                Text(pendingAction == "connect" ? "Connecting..." : "Disconnecting...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if device.connected {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Not connected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if isMultipoint {
                                Text("Audio")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color.accentColor.opacity(0.2))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(3)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded actions
            if isExpanded {
                Divider()
                    .padding(.horizontal, 10)

                HStack(spacing: 8) {
                    if let onConnect {
                        Button {
                            pendingAction = "connect"
                            onConnect()
                        } label: {
                            Label("Connect", systemImage: "link")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(pendingAction != nil)
                    }
                    if let onDisconnect {
                        Button {
                            pendingAction = "disconnect"
                            onDisconnect()
                        } label: {
                            Label("Disconnect", systemImage: "link.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(pendingAction != nil)
                    }
                    if let onSetMultipoint {
                        Button(action: onSetMultipoint) {
                            Label("Set Audio", systemImage: "speaker.wave.2")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Spacer()
                    Button(role: .destructive, action: onUnpair) {
                        Label("Unpair", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(10)
            }
        }
        .modifier(DeviceCardModifier())
        .onChange(of: device.connected) { _, _ in
            pendingAction = nil
        }
    }
}

struct DeviceCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
        } else {
            content
                .background(Color(.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 0.5)
                )
        }
    }
}
