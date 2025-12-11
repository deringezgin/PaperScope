import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
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
                    // Category Selection
                    NavigationLink(destination: CategorySelectionView()) {
                        HStack {
                            Text("Categories")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(settings.selectedCategories.count) selected")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    // Dark Mode Toggle
                    Toggle("Dark Mode", isOn: $settings.isDarkMode)
                        .padding()
                    
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
