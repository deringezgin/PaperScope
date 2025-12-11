import SwiftUI

struct RootTabView: View {
    
    init() {
        // Customizing the Tab Bar appearance for Glassmorphism feel
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            PapersView()
                .tabItem {
                    Label("Papers", systemImage: "doc.text.image")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        // Common background for the whole app can be placed here if tabs don't have their own backgrounds
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.3), Color.black.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    RootTabView()
}
