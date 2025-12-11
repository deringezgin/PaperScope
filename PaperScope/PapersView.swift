import SwiftUI

struct PapersView: View {
    let papers: [Paper] = MockData.papers

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(papers) { paper in
                        NavigationLink(destination: PaperDetailView(paper: paper)) {
                            PaperCardView(paper: paper)
                        }
                        .buttonStyle(PlainButtonStyle()) // Keeps the card look without default button styling
                    }
                }
                .padding()
            }
            .navigationTitle("Papers")
            .background {
                // Shared gradient background
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    PapersView()
}
