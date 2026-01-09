import SwiftUI

struct RootTabView: View {
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
            Tab("Home", systemImage: "house", value: 0) {
                RecentView()
            }
            
            Tab("Lists", systemImage: "list.bullet.rectangle", value: 1) {
                ListsView()
            }
            
            Tab(value: 2, role: .search) {
                SearchView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
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
