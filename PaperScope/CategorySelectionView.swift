import SwiftUI

struct CategorySelectionView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(Taxonomy.mainCategories) { category in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains(category.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert(category.id)
                                } else {
                                    expandedSections.remove(category.id)
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(category.subcategories) { subcategory in
                                Button(action: {
                                    toggleSelection(for: subcategory.code)
                                }) {
                                    HStack {
                                        Text(subcategory.name)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                        if settings.selectedCategories.contains(subcategory.code) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.secondary.opacity(0.3))
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                    .background(Color.clear) // Tappable area
                                }
                                Divider()
                            }
                        }
                    } label: {
                        HStack {
                            Text(category.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Menu {
                                Button("Select All") { selectAll(in: category) }
                                Button("Deselect All") { deselectAll(in: category) }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .padding(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .background {
            AnimatedBackgroundView()
        }
        .navigationTitle("Home Feed Categories")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(settings.selectedCategories.isEmpty ? "Select All" : "Clear All") {
                    if settings.selectedCategories.isEmpty {
                        for category in Taxonomy.mainCategories {
                            for sub in category.subcategories {
                                settings.selectedCategories.insert(sub.code)
                            }
                        }
                    } else {
                        settings.selectedCategories.removeAll()
                    }
                }
            }
        }
    }
    
    private func toggleSelection(for code: String) {
        if settings.selectedCategories.contains(code) {
           settings.selectedCategories.remove(code)
        } else {
            settings.selectedCategories.insert(code)
        }
    }
    
    private func selectAll(in category: TaxonomyCategory) {
        for sub in category.subcategories {
            settings.selectedCategories.insert(sub.code)
        }
    }
    
    private func deselectAll(in category: TaxonomyCategory) {
        for sub in category.subcategories {
            settings.selectedCategories.remove(sub.code)
        }
    }
}

#Preview {
    NavigationView {
        CategorySelectionView()
            .environmentObject(AppSettings())
    }
}
