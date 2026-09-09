import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Dokumenten-Hub: Verträge, Rider, Reiseunterlagen, Presse, Rechnungen, je Projekt/Konzert
/// zuordenbar (Konzept-Baustein "Dokumenten-Hub").
struct DocumentsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Document.createdAt, order: .reverse) private var documents: [Document]
    @State private var showingImporter = false
    @State private var pendingImportURL: URL?
    @State private var showingNewDocumentSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(DocumentCategory.allCases) { category in
                    let items = documents.filter { $0.category == category }
                    if !items.isEmpty {
                        Section(category.displayName) {
                            ForEach(items) { document in
                                NavigationLink {
                                    DocumentDetailView(document: document)
                                } label: {
                                    HStack {
                                        Image(systemName: category.symbol)
                                        VStack(alignment: .leading) {
                                            Text(document.title)
                                            if let project = document.project {
                                                Text(project.title).font(.caption).foregroundStyle(.secondary)
                                            } else if let concert = document.concert {
                                                Text(concert.title).font(.caption).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .onDelete { indices in
                                for index in indices { context.delete(items[index]) }
                            }
                        }
                    }
                }
            }
            .overlay {
                if documents.isEmpty {
                    ContentUnavailableView("Keine Dokumente", systemImage: "doc.text.magnifyingglass", description: Text("Importiere Verträge, Rider, Reiseunterlagen oder Presseunterlagen als PDF."))
                }
            }
            .navigationTitle("Dokumente")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingImporter = true } label: { Image(systemName: "plus") }
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf, .image, .plainText, .data]) { result in
                if case .success(let url) = result {
                    pendingImportURL = url
                    showingNewDocumentSheet = true
                }
            }
            .sheet(isPresented: $showingNewDocumentSheet) {
                if let pendingImportURL {
                    NewDocumentSheet(fileURL: pendingImportURL)
                }
            }
        }
    }
}

private struct NewDocumentSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Project.createdAt) private var projects: [Project]
    let fileURL: URL

    @State private var title: String
    @State private var category: DocumentCategory = .contract
    @State private var linkedProject: Project?

    init(fileURL: URL) {
        self.fileURL = fileURL
        _title = State(initialValue: fileURL.deletingPathExtension().lastPathComponent)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titel", text: $title)
                Picker("Kategorie", selection: $category) {
                    ForEach(DocumentCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.symbol).tag(category)
                    }
                }
                Picker("Projekt", selection: $linkedProject) {
                    Text("Keins").tag(Project?.none)
                    ForEach(projects) { project in
                        Text(project.title).tag(Project?.some(project))
                    }
                }
            }
            .navigationTitle("Neues Dokument")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let needsAccess = fileURL.startAccessingSecurityScopedResource()
                        defer { if needsAccess { fileURL.stopAccessingSecurityScopedResource() } }
                        let data = try? Data(contentsOf: fileURL)
                        let document = Document(title: title, category: category, fileData: data, fileExtension: fileURL.pathExtension)
                        document.project = linkedProject
                        context.insert(document)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

private struct DocumentDetailView: View {
    @Bindable var document: Document
    @Query(sort: \Project.createdAt) private var projects: [Project]

    var body: some View {
        Form {
            TextField("Titel", text: $document.title)
            Picker("Kategorie", selection: $document.category) {
                ForEach(DocumentCategory.allCases) { category in
                    Text(category.displayName).tag(category)
                }
            }
            Picker("Projekt", selection: $document.project) {
                Text("Keins").tag(Project?.none)
                ForEach(projects) { project in
                    Text(project.title).tag(Project?.some(project))
                }
            }
            if document.fileData != nil {
                LabeledContent("Datei", value: "\(document.fileExtension?.uppercased() ?? "Datei") · \(ByteCountFormatter.string(fromByteCount: Int64(document.fileData?.count ?? 0), countStyle: .file))")
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
