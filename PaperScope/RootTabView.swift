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
    
    @EnvironmentObject var navState: NavigationState
    
    var body: some View {
        TabView(selection: Binding(
            get: { navState.selectedTab },
            set: { newTab in
                if newTab == navState.selectedTab && newTab == 0 {
                    // Re-tap on Recent (0)
                    navState.refreshRecent()
                }
                navState.selectedTab = newTab
            }
        )) {
            RecentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            ListsView()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(2)
            

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
