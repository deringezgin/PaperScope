import SwiftUI

struct CategorySelectionView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        List {
            ForEach(Taxonomy.mainCategories) { category in
                Section(header: Text(category.name)) {
                    ForEach(category.subcategories) { subcategory in
                        HStack {
                            Text(subcategory.name)
                            Spacer()
                            if settings.selectedCategories.contains(subcategory.code) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle()) // Make the whole row tappable
                        .onTapGesture {
                            toggleSelection(for: subcategory.code)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Categories")
    }
    
    private func toggleSelection(for code: String) {
        if settings.selectedCategories.contains(code) {
            // Prevent deselecting the last one so we always have at least one
            if settings.selectedCategories.count > 1 {
                settings.selectedCategories.remove(code)
            }
        } else {
            settings.selectedCategories.insert(code)
        }
    }
}

#Preview {
    CategorySelectionView()
        .environmentObject(AppSettings())
}
