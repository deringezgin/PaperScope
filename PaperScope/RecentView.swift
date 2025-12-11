import SwiftUI

struct RecentView: View {
    @StateObject private var viewModel = RecentViewModel()
    @EnvironmentObject var settings: AppSettings
    @Namespace private var animationNamespace
    
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
                    } else if !viewModel.papers.isEmpty {
                        loadMoreButton
                    }
                }
                .padding()
            }
            .navigationTitle("Recent Papers")
            .background {
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            }
            .navigationDestination(for: Paper.self) { paper in
                PaperDetailView(paper: paper)
            }
            .refreshable {
                await viewModel.loadPapers(for: settings.selectedQuery)
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
    }
    
    @ViewBuilder
    private var paperList: some View {
        ForEach(viewModel.papers) { paper in
            NavigationLink(value: paper) {
                PaperCardView(paper: paper)
                // .matchedGeometryEffect(id: paper.id, in: animationNamespace)
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
}
