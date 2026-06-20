import SwiftUI

struct AnimatedBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        (colorScheme == .dark ? Color.black : Color.white)
            .ignoresSafeArea()
    }
}

#Preview {
    AnimatedBackgroundView()
}
