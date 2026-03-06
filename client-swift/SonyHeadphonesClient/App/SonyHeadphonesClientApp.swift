import SwiftUI

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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .frame(minWidth: 400, minHeight: 500)
                .onAppear { applyTheme() }
                .onChange(of: appTheme) { _, _ in applyTheme() }
        }
        .windowResizability(.contentSize)

        Settings {
            AppSettingsView()
                .frame(width: 360)
                .fixedSize()
        }
    }

    private func applyTheme() {
        NSApp.appearance = AppTheme(rawValue: appTheme)?.nsAppearance
    }
}
