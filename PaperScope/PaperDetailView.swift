import SwiftUI

struct PaperDetailView: View {
    let paper: Paper

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(paper.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(paper.authors)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Divider()

                Text("Abstract")
                    .font(.headline)
                    .padding(.top, 8)

                Text(paper.summary)
                    .font(.body)
                    .lineSpacing(6)
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
