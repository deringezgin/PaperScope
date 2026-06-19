import SwiftUI

struct PaperDetailView: View {
    let paper: Paper
    @EnvironmentObject var navState: NavigationState
    @State private var availableHtmlUrl: URL?
    
    private var candidateHtmlUrl: URL? {
        guard
            let url = paper.linkURL,
            url.host?.lowercased().hasSuffix("arxiv.org") == true,
            url.path.hasPrefix("/abs/"),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        components.path = url.path.replacingOccurrences(of: "/abs/", with: "/html/")
        components.query = nil
        components.fragment = nil
        return components.url
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MathText(paper.title, font: .title2.bold())
                    .foregroundColor(.primary)

                AuthorsFlowLayout(alignment: .leading, spacing: 6) {
                    ForEach(Array(paper.authors.enumerated()), id: \.offset) { index, author in
                        Button(action: {
                            navState.search(for: author, field: .author, exact: true)
                        }) {
                            Text(author + (index == paper.authors.count - 1 ? "" : ","))
                                .foregroundColor(.secondary)
                                .underline(true, color: .secondary.opacity(0.5))
                        }
                    }
                }
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Added on: \(paper.published.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                Divider()

                Text("Abstract")
                    .font(.headline)
                    .padding(.top, 8)

                MathText(paper.summary, font: .body)
                    .lineSpacing(6)
                
                if let url = paper.linkURL {
                    HStack(spacing: 12) {
                        Link(destination: url) {
                            HStack {
                                Text("View in arXiv")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.up.right.square")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }

                        if let readUrl = availableHtmlUrl {
                            NavigationLink(destination: ReaderView(paperUrl: readUrl)) {
                                HStack {
                                    Text("Read Paper")
                                        .fontWeight(.semibold)
                                    Image(systemName: "doc.text.viewfinder")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }

                }

            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding()
        }
        .background {
            LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: paper.id) {
            await verifyHtmlAvailability()
        }
    }
    
    private func verifyHtmlAvailability() async {
        availableHtmlUrl = nil

        guard let candidateHtmlUrl else {
            return
        }

        if await isHtmlAvailable(at: candidateHtmlUrl) {
            availableHtmlUrl = candidateHtmlUrl
        }
    }

    private func isHtmlAvailable(at url: URL) async -> Bool {
        if let headStatus = await statusCode(for: url, method: "HEAD"), headStatus != 405 {
            return (200..<300).contains(headStatus)
        }

        guard let getStatus = await statusCode(for: url, method: "GET") else {
            return false
        }
        return (200..<300).contains(getStatus)
    }

    private func statusCode(for url: URL, method: String) async -> Int? {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 8

        if method == "GET" {
            request.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode
        } catch {
            return nil
        }
    }

}

#Preview {
    NavigationView {
        PaperDetailView(paper: MockData.papers[0])
            .environmentObject(NavigationState())
    }
}

struct AuthorsFlowLayout: Layout {
    var alignment: Alignment = .leading
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return rows.last?.maxY ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for item in row.items {
                item.subview.place(at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y), proposal: .unspecified)
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        let maxWidth = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var currentRowItems: [RowItem] = []
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && !currentRowItems.isEmpty {
                rows.append(Row(items: currentRowItems, y: currentY, maxY: CGSize(width: maxWidth, height: currentY + rowHeight)))
                currentX = 0
                currentY += rowHeight + spacing
                currentRowItems = []
                rowHeight = 0
            }
            
            currentRowItems.append(RowItem(subview: subview, x: currentX))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        if !currentRowItems.isEmpty {
             rows.append(Row(items: currentRowItems, y: currentY, maxY: CGSize(width: maxWidth, height: currentY + rowHeight)))
        }
        if rows.isEmpty {
            return [Row(items: [], y: 0, maxY: .zero)]
        }
        return rows
    }
    
    private struct Row {
        var items: [RowItem]
        var y: CGFloat
        var maxY: CGSize
    }
    private struct RowItem {
        var subview: LayoutSubview
        var x: CGFloat
    }
}
