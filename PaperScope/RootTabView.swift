import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var navState: NavigationState
    
    var body: some View {
        TabView(selection: Binding(
            get: { navState.selectedTab },
            set: { newTab in
                if newTab == navState.selectedTab && newTab == 0 {
                    navState.refreshRecent()
                }
                navState.selectedTab = newTab
                if newTab == 2 {
                    DispatchQueue.main.async {
                        navState.focusSearch()
                    }
                }
            }
        )) {
            Tab("Home", systemImage: "house", value: 0) {
                RecentView()
            }
            
            Tab("Lists", systemImage: "list.bullet.rectangle", value: 1) {
                ListsView()
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: 2) {
                SearchView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppSettings())
        .environmentObject(NavigationState())
}
