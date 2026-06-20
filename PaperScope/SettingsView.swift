import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss
    var body: some View {


        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    VStack(spacing: 0) {
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
                        
                        Toggle("Dark Mode", isOn: Binding(
                            get: { settings.isDarkMode },
                            set: { newValue in
                                withAnimation {
                                    settings.isDarkMode = newValue
                                }
                            }
                        ))
                        .padding()
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
            .background {
                AnimatedBackgroundView()
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                            .padding(10)
                            .background(Color.clear)
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                }
            }
            .preferredColorScheme(settings.isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    ZStack {
        AnimatedBackgroundView()
        SettingsView()
            .environmentObject(AppSettings())
    }
}
