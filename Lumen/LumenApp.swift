import SwiftUI

@main
struct LumenApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationManager)
                .environment(\.localizationManager, localizationManager)
        }
    }
}
