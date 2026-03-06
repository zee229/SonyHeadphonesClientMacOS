import SwiftUI

struct AboutTab: View {
    @EnvironmentObject var manager: HeadphonesManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Section {
                    Text("Model")
                        .font(.headline)
                    InfoTable(rows: [
                        ("Model", manager.modelName),
                        ("MAC", manager.uniqueId),
                        ("Firmware Version", manager.fwVersion),
                        ("Series", manager.modelSeries.displayName),
                        ("Color", manager.modelColor.displayName),
                    ])
                }

            }
            .padding()
        }
    }
}

struct InfoTable: View {
    let rows: [(String, String)]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            ForEach(rows, id: \.0) { key, value in
                GridRow {
                    Text(key)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

