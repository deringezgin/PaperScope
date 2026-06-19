import Foundation

struct TaxonomyCategory: Identifiable {
    let id: String
    let name: String
    let subcategories: [TaxonomySubcategory]
}

struct TaxonomySubcategory: Identifiable, Hashable {
    let id: String
    let name: String
    let code: String
}

struct Taxonomy {
    static var mainCategories: [TaxonomyCategory] = loadCategories()
    
    private static func loadCategories() -> [TaxonomyCategory] {
        guard let url = Bundle.main.url(forResource: "taxonomy", withExtension: "csv") else {
            print("ERROR: taxonomy.csv not found in bundle")
            return []
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            var rows = content.components(separatedBy: "\n")
            
            if let header = rows.first, header.contains("main_id") {
                rows.removeFirst()
            }
            
            var categoryMap: [String: (name: String, subs: [TaxonomySubcategory])] = [:]
            
            for row in rows {
                let columns = parseCSVRow(row)
                
                if columns.count >= 5 {
                    let mainId = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let mainName = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let rawSubName = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                    let subName = rawSubName.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    let subCode = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if mainId.isEmpty { continue }
                    
                    let sub = TaxonomySubcategory(id: subCode, name: subName, code: subCode)
                    
                    if categoryMap[mainId] == nil {
                        categoryMap[mainId] = (name: mainName, subs: [])
                    }
                    categoryMap[mainId]?.subs.append(sub)
                }
            }
            
            let sortedCategories = categoryMap.map { key, value in
                TaxonomyCategory(id: key, name: value.name, subcategories: value.subs.sorted { $0.code < $1.code })
            }.sorted { $0.name < $1.name }
            
            return sortedCategories
            
        } catch {
            print("ERROR: Failed to load taxonomy csv: \(error)")
            return []
        }
    }
    
    private static func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)
        return result
    }
}
