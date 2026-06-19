import SwiftUI

struct PaperCardView: View {
    let paper: Paper

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MathText(paper.title, font: .headline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Text(paper.authorsDisplay)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            MathText(paper.summary, font: .footnote)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.2)) // Slightly stronger tint
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
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
