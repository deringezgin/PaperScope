import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar Area
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Glassy Search Capsule
                        HStack(spacing: 8) {
                            // Text Field
                            TextField("Search in \(viewModel.selectedField.rawValue)...", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .submitLabel(.search)
                                .padding(.leading, 8)
                                .onSubmit {
                                    Task { await viewModel.performSearch() }
                                }
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        // Adjustment Button
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
                            // Field Selection
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
                            
                            // Taxonomy Filters (Categories)
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
                .padding(.bottom, 8) // Spacing before results
                
                // Results Area
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
                                
                                if !viewModel.papers.isEmpty {
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
                .contentShape(Rectangle()) // Ensure empty areas are tappable
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
    }
    
    private func hideKeyboard() {
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
}
