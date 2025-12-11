import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Title is now handled by navigationTitle
                    
                    VStack(spacing: 0) {
                    // Category Selection
                        NavigationLink(destination: CategorySelectionView()) {
                            HStack {
                                Text("Home Feed Categories")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(settings.selectedCategories.count) selected")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
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
                    .padding(.top) // Add some top padding since we removed the manual title
                }
            }
            .background {
                 LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                     .ignoresSafeArea()
            }
            .navigationTitle("Settings")
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
