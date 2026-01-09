import SwiftUI
import Combine

enum SearchField: String, CaseIterable, Identifiable {
    case all = "All fields"
    case title = "Title"
    case author = "Author"
    case abstract = "Abstract"
    case journalRef = "Journal Ref"
    // case acmClass = "ACM Class" // Can add more if needed
    
    var id: String { rawValue }
    
    var prefix: String? {
        switch self {
        case .all: return "all"
        case .title: return "ti"
        case .author: return "au"
        case .abstract: return "abs"
        case .journalRef: return "jr"
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedField: SearchField = .all
    @Published var selectedCategories: Set<String> = [] // IDs of main categories
    @Published var isExactMatch: Bool = false
    
    @Published var papers: [Paper] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    
    // Advanced Search Toggles
    @Published var showAdvanced: Bool = false
    
    private let api = ArxivAPI()
    private var currentStart: Int = 0
    private let pageSize: Int = 20
    private var lastQuery: String = "" // Store last query for pagination
    
    func performSearch(reset: Bool = true) async {
        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty else { return }
        
        if reset {
            isLoading = true
            errorMessage = nil
            papers = []
            currentStart = 0
        } else {
            isLoadingMore = true
        }
        
        // Construct Query
        var queryParts: [String] = []
        
        // 1. Text Search
        let textInternal = isExactMatch ? "\"\(trimmedText)\"" : trimmedText
        
        if let prefix = selectedField.prefix {
             if prefix == "all" {
                 queryParts.append("all:\(textInternal)")
             } else {
                 queryParts.append("\(prefix):\(textInternal)")
             }
        }
        
        // 2. Category Filter
        if !selectedCategories.isEmpty {
            let catQueries = selectedCategories.map { "cat:\($0)*" } 
            let catPart = "(" + catQueries.joined(separator: "+OR+") + ")"
            queryParts.append(catPart)
        }
        
        // Combine with AND
        let finalQuery = queryParts.joined(separator: "+AND+")
        print("DEBUG: Executing Search Query (start: \(currentStart)): \(finalQuery)")
        lastQuery = finalQuery
        
        do {
            let results = try await api.fetchRecentPapers(category: finalQuery, start: currentStart, maxResults: pageSize)
            if reset {
                self.papers = results
            } else {
                self.papers.append(contentsOf: results)
            }
            // Increment for next page
            if !results.isEmpty {
                currentStart += pageSize
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        if reset {
            isLoading = false
        } else {
            isLoadingMore = false
        }
    }
    
    func loadMore() async {
        await performSearch(reset: false)
    }
}
