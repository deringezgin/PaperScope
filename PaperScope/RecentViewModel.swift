import Foundation
import Combine

@MainActor
class RecentViewModel: ObservableObject {
    @Published var papers: [Paper] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    
    private let api = ArxivAPI()
    
    // Pagination state
    private var currentStart = 0
    private let pageSize = 20
    private var lastCategory: String = "" // Keep track to handle loadMore correctly
    
    // Prevents duplicate calls
    private var canLoadMore: Bool {
        !isLoading && !isLoadingMore
    }

    // category can be "cat:cs.AI+OR+cat:cs.LG", or just "cs.AI" if single
    func loadPapers(for category: String, reset: Bool = true) async {
        if reset {
            papers = []
            currentStart = 0
            errorMessage = nil
            isLoading = true
            lastCategory = category
        } else {
            guard canLoadMore else { return }
            isLoadingMore = true
        }
        
        
        do {
            let newPapers = try await api.fetchRecentPapers(
                category: category,
                start: currentStart,
                maxResults: pageSize
            )
            
            if reset {
                papers = newPapers
            } else {
                papers.append(contentsOf: newPapers)
            }
            
            // Advance cursor
            currentStart += newPapers.count
            
        } catch {
            errorMessage = "Failed to load papers: \(error.localizedDescription)"
        }
        
        isLoading = false
        isLoadingMore = false
    }
    
    func loadMore() async {
        guard !isLoadingMore && !isLoading else { return }
        await loadPapers(for: lastCategory, reset: false)
    }
}
