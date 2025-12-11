import SwiftUI
import Combine

class NavigationState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var refreshRecentParams: UUID = UUID()
    
    func refreshRecent() {
        refreshRecentParams = UUID()
    }
}
