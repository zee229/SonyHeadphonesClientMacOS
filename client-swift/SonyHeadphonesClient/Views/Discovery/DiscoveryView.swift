import SwiftUI

struct DiscoveryView: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "headphones")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(.accentColor)
                Text("Sony Headphones Client")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Device list
            if manager.devices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No devices found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Make sure Bluetooth is on and a compatible device is paired.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                deviceList
            }

            // Bottom actions
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        manager.connect(deviceIndex: manager.selectedDeviceIndex)
                    } label: {
                        Label("Connect", systemImage: "link")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(manager.devices.isEmpty)

                    Button {
                        manager.refreshDevices()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Text("Not affiliated with Sony. Use at your own risk.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var deviceList: some View {
        let sonyDevices = manager.devices.enumerated().filter {
            HeadphonesManager.isSonyDeviceSimple(manager.deviceName(at: $0.offset))
        }
        let otherDevices = manager.devices.enumerated().filter {
            !HeadphonesManager.isSonyDeviceSimple(manager.deviceName(at: $0.offset))
        }.sorted { a, b in
            let nameA = manager.deviceName(at: a.offset)
            let nameB = manager.deviceName(at: b.offset)
            let prioA = deviceSortPriority(nameA)
            let prioB = deviceSortPriority(nameB)
            if prioA != prioB { return prioA < prioB }
            return nameA.localizedCaseInsensitiveCompare(nameB) == .orderedAscending
        }

        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if !sonyDevices.isEmpty {
                    Text("Sony Devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    ForEach(sonyDevices, id: \.offset) { idx, _ in
                        DiscoveryDeviceRow(
                            name: manager.deviceName(at: idx),
                            icon: "headphones",
                            isSony: true,
                            isSelected: manager.selectedDeviceIndex == idx
                        ) {
                            manager.selectedDeviceIndex = idx
                        }
                    }
                }

                if !otherDevices.isEmpty {
                    if !sonyDevices.isEmpty {
                        Spacer().frame(height: 4)
                    }
                    Text("Other Devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)

                    ForEach(otherDevices, id: \.offset) { idx, _ in
                        DiscoveryDeviceRow(
                            name: manager.deviceName(at: idx),
                            icon: discoveryIcon(for: manager.deviceName(at: idx)),
                            isSony: false,
                            isSelected: manager.selectedDeviceIndex == idx
                        ) {
                            manager.selectedDeviceIndex = idx
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}

private func deviceSortPriority(_ name: String) -> Int {
    let lower = name.lowercased()
    // Audio devices first
    if lower.contains("airpods") || lower.contains("headphone") || lower.contains("earbuds")
        || lower.contains("wh-") || lower.contains("wf-") || lower.contains("beats") { return 0 }
    // Phones
    if lower.contains("iphone") || lower.contains("phone") { return 1 }
    // Computers
    if lower.contains("mac") || lower.contains("ipad") { return 2 }
    // Input devices
    if lower.contains("keyboard") || lower.contains("keychron") || lower.contains("mouse")
        || lower.contains("vertical") || lower.contains("mx") { return 3 }
    // Controllers
    if lower.contains("controller") || lower.contains("dualsense") { return 4 }
    // Everything else
    return 5
}

private func discoveryIcon(for name: String) -> String {
    let lower = name.lowercased()
    if lower.contains("airpods") { return "airpodspro" }
    if lower.contains("iphone") { return "iphone" }
    if lower.contains("ipad") { return "ipad" }
    if lower.contains("macbook") { return "laptopcomputer" }
    if lower.contains("mac") { return "desktopcomputer" }
    if lower.contains("keyboard") { return "keyboard" }
    if lower.contains("mouse") || lower.contains("vertical") || lower.contains("mx") { return "computermouse" }
    if lower.contains("controller") || lower.contains("dualsense") { return "gamecontroller" }
    if lower.contains("watch") { return "applewatch" }
    if lower.contains("keychron") { return "keyboard" }
    return "wave.3.right"
}

struct DiscoveryDeviceRow: View {
    let name: String
    let icon: String
    let isSony: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSony ? .accentColor : .primary)
                    .frame(width: 24)

                Text(name)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .modifier(DiscoveryRowModifier(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }
}

struct DiscoveryRowModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        } else {
            content
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color(.separatorColor).opacity(0.5), lineWidth: 0.5)
                )
        }
    }
}
