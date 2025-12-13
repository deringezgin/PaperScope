import SwiftUI

struct PaperDetailView: View {
    let paper: Paper

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MathText(paper.title, font: .title2.bold())
                    .foregroundColor(.primary)

                Text(paper.authorsDisplay)
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Divider removed as per request
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
                    Link(destination: url) {
                        HStack {
                            Text("View in arXiv")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.up.right.square")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
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
            // Placeholder gradient background for when viewed in isolation or navigation
            LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    

}

#Preview {
    NavigationView {
        PaperDetailView(paper: MockData.papers[0])
    }
}
