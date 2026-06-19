import Foundation
import Combine

@MainActor
class AppSettings: ObservableObject {
    @Published var isDarkMode: Bool = true
    @Published var selectedCategories: Set<String> = ["cs.AI"]
    
    var selectedQuery: String {
        if selectedCategories.isEmpty {
            return "cat:cs.AI"
        }
        let queries = selectedCategories.sorted().map { "cat:\($0)" }
        return queries.joined(separator: "+OR+")
    }
}
