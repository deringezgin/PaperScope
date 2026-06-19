import Foundation
import Combine

@MainActor
class RecentViewModel: ObservableObject {
    @Published var papers: [Paper] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published private(set) var hasMoreResults: Bool = true
    @Published var errorMessage: String?
    
    private let api = ArxivAPI()
    private var currentStart = 0
    private let pageSize = 20
    private var lastCategory: String = ""
    private var activeRequestID = UUID()
    
    private var canRequestMore: Bool {
        !isLoading && !isLoadingMore && hasMoreResults && !lastCategory.isEmpty
    }

    func loadPapers(for category: String, reset: Bool = true) async {
        let requestID: UUID

        if reset {
            activeRequestID = UUID()
            requestID = activeRequestID
            currentStart = 0
            errorMessage = nil
            isLoading = true
            isLoadingMore = false
            hasMoreResults = true
            lastCategory = category
        } else {
            guard canRequestMore else { return }
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
            let newPapers = try await api.fetchRecentPapers(
                category: reset ? category : lastCategory,
                start: currentStart,
                maxResults: pageSize
            )

            guard requestID == activeRequestID else { return }
            
            if reset {
                papers = newPapers
            } else {
                papers.append(contentsOf: newPapers)
            }
            
            currentStart += newPapers.count
            hasMoreResults = newPapers.count == pageSize
            
        } catch {
            guard requestID == activeRequestID else { return }

            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            if let cocoaError = error as? CocoaError, cocoaError.code == .userCancelled {
                return
            }
            
            errorMessage = "Failed to load papers: \(error.localizedDescription)"
        }
    }
    
    func loadMore() async {
        guard canRequestMore else { return }
        await loadPapers(for: lastCategory, reset: false)
    }
}
