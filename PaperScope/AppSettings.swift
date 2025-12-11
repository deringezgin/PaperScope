import Foundation
import Combine

@MainActor
class AppSettings: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    // Store selected category codes (e.g. "cs.AI", "cs.LG")
    @Published var selectedCategories: Set<String> = ["cs.AI"]
    
    // Construct query string for ArXiv API
    // e.g. "cat:cs.AI+OR+cat:cs.LG"
    var selectedQuery: String {
        if selectedCategories.isEmpty {
            return "cat:cs.AI" // fallback
        }
        let queries = selectedCategories.map { "cat:\($0)" }
        return queries.joined(separator: " OR ")
    }
}
