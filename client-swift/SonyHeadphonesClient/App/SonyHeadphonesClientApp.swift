import SwiftUI

@main
struct SonyHeadphonesClientApp: App {
    @StateObject private var manager = HeadphonesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .frame(minWidth: 400, minHeight: 500)
        }
        .windowResizability(.contentSize)
    }
}
