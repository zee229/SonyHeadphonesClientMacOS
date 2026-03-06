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

                Section {
                    DisclosureGroup("Support Functions 1") {
                        SupportFunctionGrid(isTable1: true)
                    }
                }

                Section {
                    DisclosureGroup("Support Functions 2") {
                        SupportFunctionGrid(isTable1: false)
                    }
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

struct SupportFunctionGrid: View {
    @EnvironmentObject var manager: HeadphonesManager
    let isTable1: Bool

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 2) {
            ForEach(0..<256, id: \.self) { i in
                let val = UInt8(i)
                let supported = isTable1
                    ? manager.supportsTable1Raw(val)
                    : manager.supportsTable2Raw(val)
                if supported {
                    HStack(spacing: 8) {
                        Text(String(format: "0x%02X", i))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .leading)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
        }
    }
}
