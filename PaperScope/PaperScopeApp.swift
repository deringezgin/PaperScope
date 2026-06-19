import SwiftUI
import UIKit

@main
struct PaperScopeApp: App {
    @StateObject private var appSettings = AppSettings()
    @StateObject private var navState = NavigationState()
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appSettings)
                .environmentObject(navState)
                .preferredColorScheme(appSettings.isDarkMode ? .dark : .light)
        }
    }
}
