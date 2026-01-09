import SwiftUI

struct ListsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                Text("Your saved collections will appear here.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("(Coming soon)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                Spacer()
            }
            .navigationTitle("Lists")
             .background {
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ListsView()
}
