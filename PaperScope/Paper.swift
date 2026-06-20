import Foundation

struct Paper: Identifiable, Hashable, Codable {
    let id: String // ArXiv ID
    let title: String
    let authors: [String]
    let summary: String
    let published: Date
    let linkURL: URL?
    let primaryCategory: String?
    
    var authorsDisplay: String {
        authors.joined(separator: ", ")
    }
}
