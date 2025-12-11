import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)

                VStack(spacing: 0) {
                    settingsRow(title: "Dark Mode", detail: "Coming Soon")
                    Divider()
                    settingsRow(title: "Font Size", detail: "Coming Soon")
                    Divider()
                    settingsRow(title: "Account", detail: "Guest")
                }
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding(.horizontal)
            }
        }
        .background {
             // Shared background logic or clear if handled by parent
             Color.clear
        }
    }

    private func settingsRow(title: String, detail: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(detail)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        SettingsView()
    }
}
