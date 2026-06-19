import SwiftUI

struct RecentView: View {
    @StateObject private var viewModel = RecentViewModel()
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var navState: NavigationState
    @State private var showSettings = false
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let error = viewModel.errorMessage {
                        errorView(error)
                    }
                    
                    paperList
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else if !viewModel.papers.isEmpty && viewModel.hasMoreResults {
                        loadMoreButton
                    }
                }
                .padding()
            }
            .navigationTitle("Recent Papers")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20)) // Slightly larger icon inside
                            .foregroundColor(.primary)
                            .padding(10) // Padding for the bubble
                            .background(Color.clear) // Transparent background
                            .clipShape(Circle())
                            .contentShape(Circle()) // Improve tap area
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDragIndicator(.visible)
            }
            .background {
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
            .navigationDestination(for: Paper.self) { paper in
                PaperDetailView(paper: paper)
            }
        }
        .onAppear {
            if viewModel.papers.isEmpty {
                Task {
                    await viewModel.loadPapers(for: settings.selectedQuery)
                }
            }
        }
        .onChange(of: settings.selectedCategories) {
            Task {
                await viewModel.loadPapers(for: settings.selectedQuery)
            }
        }
        .onChange(of: navState.refreshRecentParams) {
             Task {
                 await viewModel.loadPapers(for: settings.selectedQuery, reset: true)
             }
        }
    }
    
    @ViewBuilder
    private var paperList: some View {
        ForEach(viewModel.papers) { paper in
            NavigationLink(value: paper) {
                PaperCardView(paper: paper)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Text("Error loading papers")
                .font(.headline)
                .foregroundColor(.red)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await viewModel.loadPapers(for: settings.selectedQuery)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
    
    @ViewBuilder
    private var loadMoreButton: some View {
        Button(action: {
            Task {
                await viewModel.loadMore()
            }
        }) {
            if viewModel.isLoadingMore {
                ProgressView()
            } else {
                Text("Load More")
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    RecentView()
        .environmentObject(AppSettings())
        .environmentObject(NavigationState())
}
