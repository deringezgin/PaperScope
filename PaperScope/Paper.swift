import Foundation

struct Paper: Identifiable, Hashable {
    let id: String // ArXiv ID
    let title: String
    let authors: [String]
    let summary: String
    let published: Date
    let linkURL: URL?
    let primaryCategory: String?
    
    // Computed property for easy UI display of authors
    var authorsDisplay: String {
        authors.joined(separator: ", ")
    }
}
