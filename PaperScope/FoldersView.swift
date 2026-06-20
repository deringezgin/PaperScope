import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct FoldersView: View {
    @EnvironmentObject private var foldersStore: PaperFoldersStore

    @State private var showingNewFolderSheet = false
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var showingDeleteAllConfirmation = false
    @State private var showingFolderDeleteConfirmation = false
    @State private var newFolderName = ""
    @State private var exportDocument = PaperFoldersDocument()
    @State private var statusAlert: FolderStatusAlert?
    @State private var folderToDelete: PaperFolder?

    var body: some View {
        NavigationStack {
            foldersContent
                .navigationTitle("Folders")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingNewFolderSheet = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                        .accessibilityLabel("New Folder")
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingImporter = true
                            } label: {
                                Label("Import JSON", systemImage: "square.and.arrow.down")
                            }

                            Button {
                                prepareExport()
                            } label: {
                                Label("Export JSON", systemImage: "square.and.arrow.up")
                            }
                            .disabled(foldersStore.folders.isEmpty)

                            Divider()

                            Button(role: .destructive) {
                                showingDeleteAllConfirmation = true
                            } label: {
                                Label("Delete All", systemImage: "trash")
                            }
                            .disabled(foldersStore.folders.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Folder Actions")
                    }
                }
                .navigationDestination(for: PaperFolder.ID.self) { folderID in
                    FolderDetailView(folderID: folderID)
                }
        }
        .background {
            AnimatedBackgroundView()
        }
        .sheet(isPresented: $showingNewFolderSheet, onDismiss: {
            newFolderName = ""
        }) {
            FolderNameSheet(name: $newFolderName) { folderName in
                _ = foldersStore.createFolder(named: folderName)
            }
            .presentationDetents([.height(220)])
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false,
            onCompletion: handleImport
        )
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "PaperScope Folders",
            onCompletion: handleExport
        )
        .confirmationDialog(
            "Delete all folders?",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                foldersStore.deleteAllFolders()
            }
        } message: {
            Text("This removes every folder and saved paper list from this device.")
        }
        .confirmationDialog(
            "Delete folder?",
            isPresented: $showingFolderDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                if let folderToDelete {
                    foldersStore.deleteFolder(id: folderToDelete.id)
                }
            }
        } message: {
            Text(folderToDelete.map(deleteFolderMessage(for:)) ?? "")
        }
        .alert(item: $statusAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private var foldersContent: some View {
        if foldersStore.folders.isEmpty {
            EmptyFolderState {
                showingNewFolderSheet = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                AnimatedBackgroundView()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(foldersStore.folders) { folder in
                        folderRow(folder)
                    }
                }
                .padding()
            }
            .background {
                AnimatedBackgroundView()
            }
        }
    }

    private func folderRow(_ folder: PaperFolder) -> some View {
        HStack(spacing: 10) {
            NavigationLink(value: folder.id) {
                FolderCardView(folder: folder)
            }
            .buttonStyle(ScaleButtonStyle())

            Menu {
                Button(role: .destructive) {
                    folderToDelete = folder
                    showingFolderDeleteConfirmation = true
                } label: {
                    Label("Delete Folder", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Folder Options")
        }
    }

    private func prepareExport() {
        do {
            exportDocument = PaperFoldersDocument(data: try foldersStore.exportData())
            showingExporter = true
        } catch {
            statusAlert = FolderStatusAlert(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    private func handleExport(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            statusAlert = FolderStatusAlert(
                title: "Export Failed",
                message: error.localizedDescription
            )
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFolders(from: url)
        case .failure(let error):
            statusAlert = FolderStatusAlert(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    private func importFolders(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let importedCount = try foldersStore.importFolders(from: data)
            statusAlert = FolderStatusAlert(
                title: "Import Complete",
                message: "\(importedCount) \(importedCount == 1 ? "folder" : "folders") imported."
            )
        } catch {
            statusAlert = FolderStatusAlert(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    private func deleteFolderMessage(for folder: PaperFolder) -> String {
        "This removes \(folder.name) from this device."
    }
}

struct FolderDetailView: View {
    let folderID: PaperFolder.ID

    @EnvironmentObject private var foldersStore: PaperFoldersStore
    @Environment(\.dismiss) private var dismiss

    @State private var paperToRemove: Paper?
    @State private var showingDeleteFolderConfirmation = false
    @State private var showingRemovePaperConfirmation = false

    private var folder: PaperFolder? {
        foldersStore.folder(id: folderID)
    }

    var body: some View {
        Group {
            if let folder {
                if folder.papers.isEmpty {
                    EmptyFolderDetailState()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(folder.papers) { paper in
                                paperRow(paper)
                            }
                        }
                        .padding()
                    }
                }
            } else {
                MissingFolderState()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background {
            AnimatedBackgroundView()
        }
        .navigationTitle(folder?.name ?? "Folder")
        .navigationDestination(for: Paper.self) { paper in
            PaperDetailView(paper: paper)
        }
        .toolbar {
            if folder != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteFolderConfirmation = true
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Folder Options")
                }
            }
        }
        .confirmationDialog(
            "Delete folder?",
            isPresented: $showingDeleteFolderConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                foldersStore.deleteFolder(id: folderID)
                dismiss()
            }
        } message: {
            Text("This removes the folder and its saved paper list from this device.")
        }
        .confirmationDialog(
            "Remove paper?",
            isPresented: $showingRemovePaperConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Paper", role: .destructive) {
                if let paperToRemove {
                    foldersStore.remove(paperToRemove, from: folderID)
                }
            }
        } message: {
            Text(paperToRemove.map(removePaperMessage(for:)) ?? "")
        }
    }

    private func paperRow(_ paper: Paper) -> some View {
        HStack(spacing: 10) {
            NavigationLink(value: paper) {
                PaperCardView(paper: paper)
            }
            .buttonStyle(ScaleButtonStyle())

            Button(role: .destructive) {
                paperToRemove = paper
                showingRemovePaperConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Remove Paper")
        }
    }

    private func removePaperMessage(for paper: Paper) -> String {
        "This removes \(paper.title) from this folder."
    }
}

struct PaperFolderPickerView: View {
    let paper: Paper

    @EnvironmentObject private var foldersStore: PaperFoldersStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNewFolderFocused: Bool

    @State private var newFolderName = ""

    private var canCreateFolder: Bool {
        !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if foldersStore.folders.isEmpty {
                        Text("No folders yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(foldersStore.folders) { folder in
                            Button {
                                toggle(folder)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: foldersStore.contains(paper, in: folder.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(foldersStore.contains(paper, in: folder.id) ? .blue : .secondary)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(folder.name)
                                            .foregroundColor(.primary)
                                        Text(folder.paperCountText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack(spacing: 10) {
                        TextField("New folder", text: $newFolderName)
                            .focused($isNewFolderFocused)
                            .submitLabel(.done)
                            .onSubmit(createFolderWithPaper)

                        Button(action: createFolderWithPaper) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canCreateFolder)
                        .accessibilityLabel("Create Folder")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                AnimatedBackgroundView()
            }
            .navigationTitle("Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle(_ folder: PaperFolder) {
        if foldersStore.contains(paper, in: folder.id) {
            foldersStore.remove(paper, from: folder.id)
        } else {
            foldersStore.add(paper, to: folder.id)
        }
    }

    private func createFolderWithPaper() {
        let folderName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !folderName.isEmpty else {
            isNewFolderFocused = true
            return
        }

        _ = foldersStore.createFolder(named: folderName, adding: paper)
        newFolderName = ""
        isNewFolderFocused = false
    }
}

private struct FolderCardView: View {
    let folder: PaperFolder

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 5) {
                Text(folder.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(folder.paperCountText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Updated \(folder.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

private struct EmptyFolderState: View {
    let createAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(.secondary)

            Text("No Folders")
                .font(.headline)

            Button(action: createAction) {
                Label("New Folder", systemImage: "folder.badge.plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct EmptyFolderDetailState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.secondary)

            Text("No Papers")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
    }
}

private struct MissingFolderState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(.secondary)

            Text("Folder Not Found")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
    }
}

private struct FolderNameSheet: View {
    @Binding var name: String
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Folder name", text: $name)
                    .focused($isFocused)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onSubmit(create)

                Spacer()
            }
            .padding()
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(!canCreate)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    private func create() {
        let folderName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !folderName.isEmpty else { return }

        onCreate(folderName)
        dismiss()
    }
}

private struct FolderStatusAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct PaperFoldersDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json]
    }

    var data: Data = Data()

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    FoldersView()
        .environmentObject(PaperFoldersStore(storageKey: "PaperScope.previewFolders"))
        .environmentObject(NavigationState())
}
