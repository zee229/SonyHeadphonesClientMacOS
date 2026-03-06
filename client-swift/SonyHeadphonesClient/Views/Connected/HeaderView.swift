import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        VStack(spacing: 8) {
            // Top bar: model name + badges + actions
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .foregroundColor(.accentColor)
                    Text(manager.modelName)
                        .fontWeight(.medium)
                }

                // Badges
                HStack(spacing: 6) {
                    if manager.supports(.codecIndicator) {
                        BadgeView(text: manager.audioCodec.displayName)
                    }
                    if manager.upscalingEnabled {
                        BadgeView(text: manager.upscalingType.displayName)
                    }
                }

                Spacer()

                // Action buttons
                Button {
                    manager.disconnect()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Disconnect")

                if manager.supports(.powerOff) {
                    Button {
                        manager.shutdown()
                    } label: {
                        Image(systemName: "power.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Shutdown headphones")
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Battery + Now Playing
            HStack(alignment: .top, spacing: 16) {
                // Battery column
                VStack(alignment: .leading, spacing: 4) {
                    let supportSingle = manager.supports(.batteryLevelIndicator) || manager.supports(.batteryLevelWithThreshold)
                    let supportLR = manager.supports(.leftRightBatteryLevelIndicator) || manager.supports(.lrBatteryLevelWithThreshold)
                    let supportCase = manager.supports(.cradleBatteryLevelIndicator) || manager.supports(.cradleBatteryLevelWithThreshold)

                    if supportSingle && !supportLR && manager.batteryL.threshold > 0 {
                        BatteryRow(label: "Battery", battery: manager.batteryL)
                    }
                    if supportLR {
                        if manager.batteryL.threshold > 0 {
                            BatteryRow(label: "L", battery: manager.batteryL)
                        }
                        if manager.batteryR.threshold > 0 {
                            BatteryRow(label: "R", battery: manager.batteryR)
                        }
                    }
                    if supportCase && manager.batteryCase.threshold > 0 {
                        BatteryRow(label: "Case", battery: manager.batteryCase)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Now Playing column
                VStack(alignment: .leading, spacing: 2) {
                    Label("Now Playing", systemImage: "speaker.wave.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !manager.playTrackTitle.isEmpty {
                        Text(manager.playTrackTitle).font(.caption).lineLimit(1)
                    }
                    if !manager.playTrackAlbum.isEmpty {
                        Text(manager.playTrackAlbum).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                    if !manager.playTrackArtist.isEmpty {
                        Text(manager.playTrackArtist).font(.caption2).foregroundColor(.secondary).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct BadgeView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentColor, lineWidth: 1.5)
            )
    }
}

struct BatteryRow: View {
    let label: String
    let battery: BatteryInfo

    var body: some View {
        HStack(spacing: 6) {
            Text("\(label): \(battery.level)%")
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            ProgressView(value: Double(battery.level), total: 100)
                .tint(batteryColor)
                .frame(maxWidth: .infinity)
            if !battery.charging.displayName.isEmpty {
                Text(battery.charging.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var batteryColor: Color {
        if battery.level <= 15 { return .red }
        if battery.level <= 30 { return .orange }
        return .green
    }
}
