import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @EnvironmentObject var navState: NavigationState
    
    @State private var showFilters = false
    @State private var path = NavigationPath()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Search in \(viewModel.selectedField.rawValue)...", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .submitLabel(.search)
                                .focused($isSearchFocused)
                                .padding(.leading, 8)
                                .onSubmit {
                                    performSearch()
                                }
                            
                            Spacer()

                            Button(action: performSearch) {
                                Image(systemName: viewModel.isLoading ? "hourglass" : "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(searchButtonColor)
                                    .frame(width: 32, height: 32)
                                    .contentShape(Circle())
                            }
                            .disabled(viewModel.isLoading)
                            .accessibilityLabel("Search")
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                showFilters.toggle()
                            }
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title3)
                                .foregroundColor(showFilters ? .white : .primary)
                                .padding(12)
                                .background(showFilters ? Color.blue : Color.clear)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if showFilters {
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Field")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
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
                                }
                                .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                                .padding(.horizontal)

                             Toggle("Exact Match", isOn: $viewModel.isExactMatch)
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            Divider()
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Categories")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(Taxonomy.mainCategories) { category in
                                            FilterChip(
                                                title: category.name,
                                                isSelected: viewModel.selectedCategories.contains(category.id),
                                                action: {
                                                    if viewModel.selectedCategories.contains(category.id) {
                                                        viewModel.selectedCategories.remove(category.id)
                                                    } else {
                                                        viewModel.selectedCategories.insert(category.id)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                    }
                }
                .padding(.bottom, 8)
                
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.papers.isEmpty && !viewModel.searchText.isEmpty {
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No results found.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
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
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
                .overlay {
                    if showFilters {
                        Color.black.opacity(0.001)
                            .onTapGesture {
                                hideKeyboard()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    showFilters = false
                                }
                            }
                    }
                }
            }
            .navigationTitle("Search")
            .background {
                AnimatedBackgroundView()
            }
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
    
    private var canSubmitSearch: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var searchButtonColor: Color {
        canSubmitSearch && !viewModel.isLoading ? .blue : .secondary
    }

    private func performSearch() {
        guard canSubmitSearch else {
            focusSearchField()
            return
        }

        Task {
            await viewModel.performSearch()
        }
    }

    private func focusSearchField() {
        path = NavigationPath()
        showFilters = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSearchFocused = true
        }
    }

    private func hideKeyboard() {
        isSearchFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
