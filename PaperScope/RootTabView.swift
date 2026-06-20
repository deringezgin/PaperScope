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
                if newTab == 1 {
                    DispatchQueue.main.async {
                        navState.focusSearch()
                    }
                }
            }
        )) {
            Tab("Home", systemImage: "house", value: 0) {
                RecentView()
            }
            
            Tab("Search", systemImage: "magnifyingglass", value: 1) {
                SearchView()
            }

            Tab("Folders", systemImage: "folder", value: 2) {
                FoldersView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppSettings())
        .environmentObject(NavigationState())
        .environmentObject(PaperFoldersStore(storageKey: "PaperScope.previewFolders"))
}
