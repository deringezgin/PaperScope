import Combine
import Foundation

struct PaperFolder: Identifiable, Hashable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var papers: [Paper]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        papers: [Paper] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.papers = papers
    }

    var paperCountText: String {
        "\(papers.count) \(papers.count == 1 ? "paper" : "papers")"
    }
}

struct PaperFoldersExport: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date = Date()
    var folders: [PaperFolder]
}

enum PaperFoldersStoreError: LocalizedError {
    case invalidImportFile

    var errorDescription: String? {
        switch self {
        case .invalidImportFile:
            "The selected JSON file does not contain PaperScope folders."
        }
    }
}

@MainActor
final class PaperFoldersStore: ObservableObject {
    @Published private(set) var folders: [PaperFolder] = []

    private let userDefaults: UserDefaults
    private let storageKey: String

    init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "PaperScope.paperFolders.v1"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.folders = loadFolders()
    }

    @discardableResult
    func createFolder(named rawName: String, adding paper: Paper? = nil) -> PaperFolder? {
        let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let name = uniqueName(for: trimmedName)
        let folder = PaperFolder(name: name, papers: paper.map { [$0] } ?? [])
        folders.insert(folder, at: 0)
        persist()
        return folder
    }

    func deleteFolder(id: PaperFolder.ID) {
        folders.removeAll { $0.id == id }
        persist()
    }

    func deleteFolders(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where folders.indices.contains(index) {
            folders.remove(at: index)
        }
        persist()
    }

    func deleteAllFolders() {
        folders.removeAll()
        persist()
    }

    func folder(id: PaperFolder.ID) -> PaperFolder? {
        folders.first { $0.id == id }
    }

    func contains(_ paper: Paper, in folderID: PaperFolder.ID) -> Bool {
        folder(id: folderID)?.papers.contains(where: { $0.id == paper.id }) ?? false
    }

    func add(_ paper: Paper, to folderID: PaperFolder.ID) {
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
        guard !folders[index].papers.contains(where: { $0.id == paper.id }) else { return }

        var folder = folders[index]
        folder.papers.insert(paper, at: 0)
        folder.updatedAt = Date()
        folders[index] = folder
        persist()
    }

    func remove(_ paper: Paper, from folderID: PaperFolder.ID) {
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }

        var folder = folders[index]
        folder.papers.removeAll { $0.id == paper.id }
        folder.updatedAt = Date()
        folders[index] = folder
        persist()
    }

    func removePapers(at offsets: IndexSet, from folderID: PaperFolder.ID) {
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }

        var folder = folders[index]
        for paperIndex in offsets.sorted(by: >) where folder.papers.indices.contains(paperIndex) {
            folder.papers.remove(at: paperIndex)
        }
        folder.updatedAt = Date()
        folders[index] = folder
        persist()
    }

    func exportData() throws -> Data {
        let export = PaperFoldersExport(folders: folders)
        return try Self.makeEncoder().encode(export)
    }

    @discardableResult
    func importFolders(from data: Data) throws -> Int {
        let importedFolders = try decodeImport(data: data)
        guard !importedFolders.isEmpty else {
            throw PaperFoldersStoreError.invalidImportFile
        }

        var existingIDs = Set(folders.map(\.id))
        var existingNames = Set(folders.map { normalizedName($0.name) })
        var mergedFolders: [PaperFolder] = []

        for importedFolder in importedFolders {
            let trimmedName = importedFolder.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }

            let folderID: UUID
            if existingIDs.contains(importedFolder.id) {
                folderID = UUID()
            } else {
                folderID = importedFolder.id
            }
            existingIDs.insert(folderID)

            let folderName = uniqueName(for: trimmedName, existingNames: existingNames)
            existingNames.insert(normalizedName(folderName))

            var seenPaperIDs: Set<String> = []
            let papers = importedFolder.papers.filter { paper in
                seenPaperIDs.insert(paper.id).inserted
            }

            mergedFolders.append(
                PaperFolder(
                    id: folderID,
                    name: folderName,
                    createdAt: importedFolder.createdAt,
                    updatedAt: Date(),
                    papers: papers
                )
            )
        }

        guard !mergedFolders.isEmpty else {
            throw PaperFoldersStoreError.invalidImportFile
        }

        folders.insert(contentsOf: mergedFolders, at: 0)
        persist()
        return mergedFolders.count
    }

    private func loadFolders() -> [PaperFolder] {
        guard let data = userDefaults.data(forKey: storageKey) else { return [] }

        if let folders = try? Self.makeDecoder().decode([PaperFolder].self, from: data) {
            return folders
        }

        if let export = try? Self.makeDecoder().decode(PaperFoldersExport.self, from: data) {
            return export.folders
        }

        return []
    }

    private func persist() {
        guard let data = try? Self.makeEncoder().encode(folders) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func decodeImport(data: Data) throws -> [PaperFolder] {
        let decoder = Self.makeDecoder()

        if let export = try? decoder.decode(PaperFoldersExport.self, from: data) {
            return export.folders
        }

        if let folders = try? decoder.decode([PaperFolder].self, from: data) {
            return folders
        }

        throw PaperFoldersStoreError.invalidImportFile
    }

    private func uniqueName(for name: String) -> String {
        uniqueName(for: name, existingNames: Set(folders.map { normalizedName($0.name) }))
    }

    private func uniqueName(for name: String, existingNames: Set<String>) -> String {
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !existingNames.contains(normalizedName(baseName)) else {
            var suffix = 2
            while existingNames.contains(normalizedName("\(baseName) (\(suffix))")) {
                suffix += 1
            }
            return "\(baseName) (\(suffix))"
        }
        return baseName
    }

    private func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
