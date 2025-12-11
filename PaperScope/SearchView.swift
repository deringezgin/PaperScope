import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search papers...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
                
                Text("Search functionality coming soon.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Search")
            .background {
                 LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    SearchView()
}
