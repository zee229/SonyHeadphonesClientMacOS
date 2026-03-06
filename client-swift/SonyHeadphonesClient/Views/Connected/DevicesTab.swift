import SwiftUI

struct DevicesTab: View {
    @EnvironmentObject var manager: HeadphonesManager
    @State private var selectedMac: String?

    private var supportDeviceMgmt: Bool {
        manager.supports(.pairingDeviceManagementClassicBT)
        || manager.supports(.pairingDeviceManagementWithBTClassOfDeviceClassicBT)
        || manager.supports(.pairingDeviceManagementWithBTClassOfDeviceClassicLE)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !supportDeviceMgmt {
                    Text("Please enable \"Connect to 2 devices simultaneously\" in System settings to manage devices.")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }

                let connected = manager.pairedDevices.filter(\.connected)
                let paired = manager.pairedDevices.filter { !$0.connected }

                if !connected.isEmpty {
                    Section {
                        Text("Connected")
                            .font(.headline)
                        ForEach(connected) { device in
                            DeviceRow(
                                device: device,
                                isSelected: selectedMac == device.id,
                                isMultipoint: device.id == manager.multipointDeviceMac,
                                onSelect: { toggleSelection(device.id) },
                                onDisconnect: { manager.disconnectPairedDevice(device.id) },
                                onConnect: nil,
                                onUnpair: { manager.unpairDevice(device.id) },
                                onSetMultipoint: { manager.setMultipointDeviceMac(device.id) }
                            )
                        }
                    }
                }

                if !paired.isEmpty {
                    Section {
                        Text("Paired")
                            .font(.headline)
                        ForEach(paired) { device in
                            DeviceRow(
                                device: device,
                                isSelected: selectedMac == device.id,
                                isMultipoint: false,
                                onSelect: { toggleSelection(device.id) },
                                onDisconnect: nil,
                                onConnect: { manager.connectPairedDevice(device.id) },
                                onUnpair: { manager.unpairDevice(device.id) },
                                onSetMultipoint: nil
                            )
                        }
                    }
                }

                Divider()

                // Pairing Mode
                if manager.pairingMode {
                    VStack(spacing: 8) {
                        Text("Pairing...")
                            .font(.callout)
                        ProgressView()
                            .controlSize(.small)
                        Button("Stop") {
                            manager.pairingMode = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
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
            .padding()
            .disabled(!supportDeviceMgmt)
        }
    }

    private func toggleSelection(_ mac: String) {
        selectedMac = selectedMac == mac ? nil : mac
    }
}

struct DeviceRow: View {
    let device: PairedDevice
    let isSelected: Bool
    let isMultipoint: Bool
    let onSelect: () -> Void
    let onDisconnect: (() -> Void)?
    let onConnect: (() -> Void)?
    let onUnpair: () -> Void
    let onSetMultipoint: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: onSelect) {
                HStack {
                    if isMultipoint {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.accentColor)
                    }
                    Text(device.name)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isSelected {
                Divider()
                HStack(spacing: 8) {
                    if let onDisconnect {
                        Button("Disconnect", action: onDisconnect)
                            .buttonStyle(.bordered)
                    }
                    if let onConnect {
                        Button("Connect", action: onConnect)
                            .buttonStyle(.borderedProminent)
                    }
                    if let onSetMultipoint {
                        Button("Set Audio", action: onSetMultipoint)
                            .buttonStyle(.bordered)
                    }
                    Button("Unpair", role: .destructive, action: onUnpair)
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
