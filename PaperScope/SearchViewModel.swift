import SwiftUI
import Combine

enum SearchField: String, CaseIterable, Identifiable {
    case all = "All fields"
    case title = "Title"
    case author = "Author"
    case abstract = "Abstract"
    case journalRef = "Journal Ref"
    
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
    @Published private(set) var hasMoreResults: Bool = true
    @Published private(set) var completedSearchQuery: String?
    @Published var errorMessage: String?
    
    @Published var showAdvanced: Bool = false
    
    private let api = ArxivAPI()
    private var currentStart: Int = 0
    private let pageSize: Int = 20
    private var lastQuery: String = ""
    private var activeRequestID = UUID()

    private var canRequestMore: Bool {
        !isLoading && !isLoadingMore && hasMoreResults && !lastQuery.isEmpty
    }

    var shouldShowNoResults: Bool {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isLoading, errorMessage == nil else { return false }
        return completedSearchQuery == makeQuery(for: trimmedText) && papers.isEmpty
    }
    
    func performSearch(reset: Bool = true) async {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            if reset {
                activeRequestID = UUID()
                papers = []
                errorMessage = nil
                isLoading = false
                isLoadingMore = false
                currentStart = 0
                lastQuery = ""
                hasMoreResults = false
                completedSearchQuery = nil
            }
            return
        }
        
        let finalQuery = makeQuery(for: trimmedText)
        let requestID: UUID
        
        if reset {
            activeRequestID = UUID()
            requestID = activeRequestID
            isLoading = true
            isLoadingMore = false
            errorMessage = nil
            papers = []
            currentStart = 0
            hasMoreResults = true
            lastQuery = finalQuery
            completedSearchQuery = nil
        } else {
            guard canRequestMore else { return }
            guard finalQuery == lastQuery else {
                await performSearch(reset: true)
                return
            }
            requestID = activeRequestID
            isLoadingMore = true
        }

        defer {
            if requestID == activeRequestID {
                isLoading = false
                isLoadingMore = false
            }
        }
        
        do {
            let results = try await api.fetchRecentPapers(category: finalQuery, start: currentStart, maxResults: pageSize)
            guard requestID == activeRequestID else { return }

            if reset {
                self.papers = results
            } else {
                self.papers.append(contentsOf: results)
            }
            currentStart += results.count
            hasMoreResults = results.count == pageSize
            if reset {
                completedSearchQuery = finalQuery
            }
        } catch {
            guard requestID == activeRequestID else { return }
            self.errorMessage = error.localizedDescription
        }
    }

    private func makeQuery(for trimmedText: String) -> String {
        var queryParts: [String] = []
        let textInternal = isExactMatch ? "\"\(trimmedText)\"" : trimmedText
        
        if let prefix = selectedField.prefix {
             if prefix == "all" {
                 queryParts.append("all:\(textInternal)")
             } else {
                 queryParts.append("\(prefix):\(textInternal)")
             }
        }
        
        if !selectedCategories.isEmpty {
            let catQueries = selectedCategories.sorted().map { "cat:\($0)*" }
            let catPart = "(" + catQueries.joined(separator: "+OR+") + ")"
            queryParts.append(catPart)
        }
        
        return queryParts.joined(separator: "+AND+")
    }
    
    func loadMore() async {
        guard canRequestMore else { return }
        await performSearch(reset: false)
    }

    func clearSearch() {
        activeRequestID = UUID()
        searchText = ""
        papers = []
        errorMessage = nil
        isLoading = false
        isLoadingMore = false
        currentStart = 0
        lastQuery = ""
        hasMoreResults = false
        completedSearchQuery = nil
    }
}
