import SwiftUI

struct PaperCardView: View {
    let paper: Paper

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(paper.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Text(paper.authorsDisplay)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(paper.summary)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        PaperCardView(paper: MockData.papers[0])
            .padding()
    }
}
