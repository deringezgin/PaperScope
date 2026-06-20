import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var navState: NavigationState
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var showFilters = false
    @State private var path = NavigationPath()
    @State private var searchFocusRequest = UUID()

    var body: some View {
        NavigationStack(path: $path) {
            resultsContent
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: Paper.self) { paper in
                PaperDetailView(paper: paper)
            }
        }
        .onAppear {
            if let request = navState.pendingSearch {
                path = NavigationPath()
                viewModel.searchText = request.term
                viewModel.selectedField = request.field
                viewModel.isExactMatch = request.exact
                Task {
                    await viewModel.performSearch()
                    navState.pendingSearch = nil
                }
            }
        }
        .onChange(of: navState.searchFocusParams) {
            focusSearchField()
        }
        .onChange(of: navState.pendingSearch) { _, request in
            if let request = request {
                path = NavigationPath()
                viewModel.searchText = request.term
                viewModel.selectedField = request.field
                viewModel.isExactMatch = request.exact
                Task {
                    await viewModel.performSearch()
                    navState.pendingSearch = nil
                }
            }
        }
    }

    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    TextField(searchPrompt, text: $viewModel.searchText)
                        .focused($isSearchFieldFocused)
                        .submitLabel(.search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.title3)
                        .onSubmit {
                            performSearch()
                        }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }

                    Button(action: performSearch) {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                        }
                        .foregroundColor(searchActionForegroundColor)
                        .frame(width: 34, height: 34)
                        .background(searchActionBackgroundColor)
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Search")
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(controlBackgroundColor)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showFilters.toggle()
                    }
                } label: {
                    Image(systemName: showFilters ? "slider.horizontal.3" : "line.3.horizontal.decrease")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(showFilters ? .white : .primary)
                        .frame(width: 54, height: 54)
                        .background(showFilters ? Color.blue : controlBackgroundColor)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.primary.opacity(showFilters ? 0 : 0.08), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showFilters ? "Hide filters" : "Show filters")
            }

            if showFilters {
                filterPanel
                    .transition(.searchFilterReveal)
            }
        }
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SearchField.allCases) { field in
                        FilterChip(
                            title: field.rawValue,
                            isSelected: viewModel.selectedField == field,
                            action: {
                                viewModel.selectedField = field
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }

            Toggle("Exact Match", isOn: $viewModel.isExactMatch)
                .font(.subheadline)
                .padding(.horizontal, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Taxonomy.mainCategories) { category in
                        FilterChip(
                            title: category.name,
                            isSelected: viewModel.selectedCategories.contains(category.id),
                            action: {
                                toggleCategory(category.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 12)
        .background(controlBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    searchHeader
                        .id(SearchScrollTarget.header)

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, minHeight: 360)
                    } else if let error = viewModel.errorMessage {
                        errorState(error)
                    } else if viewModel.shouldShowNoResults {
                        noResultsState
                    } else {
                        paperResults
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background {
                AnimatedBackgroundView()
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: searchFocusRequest) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                    proxy.scrollTo(SearchScrollTarget.header, anchor: .top)
                }
                isSearchFieldFocused = true
            }
        }
    }

    private func errorState(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var noResultsState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No results found.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    @ViewBuilder
    private var paperResults: some View {
        ForEach(viewModel.papers) { paper in
            NavigationLink(value: paper) {
                PaperCardView(paper: paper)
            }
            .buttonStyle(ScaleButtonStyle())
        }

        if !viewModel.papers.isEmpty && viewModel.hasMoreResults {
            Button(action: {
                Task { await viewModel.loadMore() }
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
            .background(controlBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var canSubmitSearch: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var controlBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.72)
    }

    private var searchPrompt: String {
        "Search \(viewModel.selectedField.rawValue.lowercased())"
    }

    private var searchActionBackgroundColor: Color {
        canSubmitSearch ? .blue : Color.gray.opacity(0.22)
    }

    private var searchActionForegroundColor: Color {
        canSubmitSearch ? .white : .secondary
    }

    private func performSearch() {
        guard canSubmitSearch else {
            focusSearchField()
            return
        }

        if showFilters {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showFilters = false
            }
        }

        Task {
            await viewModel.performSearch()
        }
    }

    private func focusSearchField() {
        path = NavigationPath()
        showFilters = false
        searchFocusRequest = UUID()
    }

    private func toggleCategory(_ id: String) {
        if viewModel.selectedCategories.contains(id) {
            viewModel.selectedCategories.remove(id)
        } else {
            viewModel.selectedCategories.insert(id)
        }
    }
}

private enum SearchScrollTarget {
    static let header = "search-header"
}

private struct SearchFilterRevealModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(
                Rectangle()
                    .scaleEffect(x: 1, y: max(progress, 0.01), anchor: .top)
            )
            .opacity(Double(progress))
            .offset(y: -8 * (1 - progress))
    }
}

private extension AnyTransition {
    static var searchFilterReveal: AnyTransition {
        .modifier(
            active: SearchFilterRevealModifier(progress: 0),
            identity: SearchFilterRevealModifier(progress: 1)
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(NavigationState())
}
