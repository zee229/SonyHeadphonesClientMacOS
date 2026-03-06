import SwiftUI

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

