import SwiftUI
import ServiceManagement

enum AppTheme: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

@main
struct SonyHeadphonesClientApp: App {
    @StateObject private var manager = HeadphonesManager()
    @AppStorage("appTheme") private var appTheme: Int = 0
    @AppStorage("menuBarEnabled") private var menuBarEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .frame(minWidth: 400, minHeight: 500)
                .onAppear { applyTheme(); registerLaunchAtLoginIfNeeded() }
                .onChange(of: appTheme) { _, _ in applyTheme() }
        }
        .windowResizability(.contentSize)

        Settings {
            AppSettingsView()
                .frame(width: 360)
                .fixedSize()
        }

        MenuBarExtra(isInserted: $menuBarEnabled) {
            MenuBarPopoverView()
                .environmentObject(manager)
        } label: {
            MenuBarLabel(manager: manager)
        }
        .menuBarExtraStyle(.window)
    }

    private func applyTheme() {
        NSApp.appearance = AppTheme(rawValue: appTheme)?.nsAppearance
    }

    private func registerLaunchAtLoginIfNeeded() {
        if !UserDefaults.standard.bool(forKey: "didSetupLaunchAtLogin") {
            UserDefaults.standard.set(true, forKey: "didSetupLaunchAtLogin")
            try? SMAppService.mainApp.register()
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var manager: HeadphonesManager
    @AppStorage("menuBarIconStyle") private var iconStyle: Int = 1

    private var batteryText: String? {
        guard manager.connectionState == .connected else { return nil }
        let levels = [manager.batteryL, manager.batteryR].filter { $0.threshold > 0 }
        guard let min = levels.min(by: { $0.level < $1.level }) else { return nil }
        return "\(min.level)%"
    }

    var body: some View {
        HStack(spacing: 2) {
            if iconStyle != 2 {
                Image(systemName: "headphones")
            }
            if iconStyle != 0, let text = batteryText {
                Text(text)
            }
        }
    }
}
