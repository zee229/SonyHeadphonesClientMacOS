import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        VStack(spacing: 16) {
            Text("SonyHeadphonesClient")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 2.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            if manager.devices.isEmpty {
                VStack(spacing: 8) {
                    Divider()
                    Label("No devices available. Make sure your Bluetooth radio is turned on, and a compatible device is connected.",
                          systemImage: "exclamationmark.triangle")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            } else {
                deviceLists
            }

            HStack(spacing: 12) {
                Button {
                    manager.connect(deviceIndex: manager.selectedDeviceIndex)
                } label: {
                    Label("Connect", systemImage: "link")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.devices.isEmpty)

                Button {
                    manager.refreshDevices()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Divider()

            Text("This product is not affiliated with Sony. Use at your own risk.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    @ViewBuilder
    private var deviceLists: some View {
        let sonyDevices = manager.devices.enumerated().filter {
            HeadphonesManager.isSonyDeviceSimple(manager.deviceName(at: $0.offset))
        }
        let otherDevices = manager.devices.enumerated().filter {
            !HeadphonesManager.isSonyDeviceSimple(manager.deviceName(at: $0.offset))
        }

        List(selection: Binding(
            get: { manager.selectedDeviceIndex },
            set: { manager.selectedDeviceIndex = $0 }
        )) {
            if !sonyDevices.isEmpty {
                Section("Sony Devices") {
                    ForEach(sonyDevices, id: \.offset) { idx, _ in
                        Text(manager.deviceName(at: idx))
                            .tag(idx)
                    }
                }
            }
            if !otherDevices.isEmpty {
                Section("Other Devices") {
                    ForEach(otherDevices, id: \.offset) { idx, _ in
                        Text(manager.deviceName(at: idx))
                            .tag(idx)
                    }
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minHeight: 150)
    }
}
