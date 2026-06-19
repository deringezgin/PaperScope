import SwiftUI
import Combine

struct SearchRequest: Equatable {
    let term: String
    let field: SearchField
    let exact: Bool
}

class NavigationState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingSearch: SearchRequest?
    @Published var refreshRecentParams: UUID = UUID()
    @Published var searchFocusParams: UUID = UUID()
    
    func refreshRecent() {
        refreshRecentParams = UUID()
    }
    
    func search(for term: String, field: SearchField, exact: Bool = false) {
        pendingSearch = SearchRequest(term: term, field: field, exact: exact)
        selectedTab = 2
    }

    func focusSearch() {
        searchFocusParams = UUID()
    }
}
