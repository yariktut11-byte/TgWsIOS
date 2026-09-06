import SwiftUI

/// Точка входа приложения
@main
struct TgWsApp: App {
    @StateObject private var proxyManager = ProxyManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(proxyManager)
        }
    }
}
