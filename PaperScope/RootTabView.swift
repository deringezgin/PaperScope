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
                if newTab == navState.selectedTab && newTab == 2 {
                    navState.focusSearch()
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
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppSettings())
        .environmentObject(NavigationState())
}
