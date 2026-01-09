import SwiftUI
import LaTeXSwiftUI

struct MathText: View {
    let text: String
    let font: Font
    
    init(_ text: String, font: Font = .body) {
        self.text = text
        self.font = font
    }
    
    var body: some View {
        LaTeX(cleanText(text))
            .font(font)
            .parsingMode(.onlyEquations)
            .renderingStyle(.original) // Render text first to avoid 0-height errors during transitions
    }
    
    private func cleanText(_ input: String) -> String {
        // Normalize newlines to spaces for cleaner list rendering
        return input.replacingOccurrences(of: "\n", with: " ")
    }
}
