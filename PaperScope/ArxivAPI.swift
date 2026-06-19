import Foundation

enum ArxivAPIError: Error {
    case invalidURL
    case parsingError(Error)
    case networkError(Error)
}

struct ArxivAPI {
    private let baseURL = "https://export.arxiv.org/api/query"
    
    func fetchRecentPapers(category: String, start: Int = 0, maxResults: Int = 20) async throws -> [Paper] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "search_query", value: category),
            URLQueryItem(name: "sortBy", value: "submittedDate"),
            URLQueryItem(name: "sortOrder", value: "descending"),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "max_results", value: String(maxResults))
        ]
        
        guard let url = components?.url else {
            throw ArxivAPIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let parser = ArxivXMLParser(data: data)
        return try parser.parse()
    }
}

class ArxivXMLParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private var papers: [Paper] = []
    private var currentElement: String = ""
    private var currentTitle: String = ""
    private var currentSummary: String = ""
    private var currentId: String = ""
    private var currentPublished: String = ""
    private var currentAuthors: [String] = []
    private var currentEntryLink: String?
    private var currentPrimaryCategory: String?
    private var currentTextBuffer: String = ""
    
    init(data: Data) {
        self.parser = XMLParser(data: data)
        super.init()
        self.parser.delegate = self
    }
    
    func parse() throws -> [Paper] {
        if parser.parse() {
            return papers
        } else {
            if let error = parser.parserError {
                throw ArxivAPIError.parsingError(error)
            }
            return []
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentTextBuffer = ""
        
        if elementName == "entry" {
            currentTitle = ""
            currentSummary = ""
            currentId = ""
            currentPublished = ""
            currentAuthors = []
            currentEntryLink = nil
            currentPrimaryCategory = nil
        }
        
        if elementName == "link", let rel = attributeDict["rel"], rel == "alternate", let href = attributeDict["href"] {
            currentEntryLink = href
        }
        
        if elementName == "arxiv:primary_category", let term = attributeDict["term"] {
            currentPrimaryCategory = term
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentTextBuffer += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedText = currentTextBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "id":
            currentId = trimmedText
        case "title":
            currentTitle = trimmedText.replacingOccurrences(of: "\n", with: " ")
        case "summary":
            currentSummary = trimmedText.replacingOccurrences(of: "\n", with: " ")
        case "published":
            currentPublished = trimmedText
        case "name":
            if !trimmedText.isEmpty {
                currentAuthors.append(trimmedText)
            }
        case "entry":
            let paper = Paper(
                id: currentId,
                title: currentTitle,
                authors: currentAuthors,
                summary: currentSummary,
                published: ISO8601DateFormatter().date(from: currentPublished) ?? Date(),
                linkURL: currentEntryLink.flatMap { URL(string: $0) },
                primaryCategory: currentPrimaryCategory
            )
            papers.append(paper)
        default:
            break
        }
    }
}
