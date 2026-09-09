import SwiftUI
import SwiftData

/// §21 Content Library: häufig verwendete Inhalte zentral gespeichert.
struct ContentLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LibraryItem.title) private var items: [LibraryItem]
    @State private var showingNewItem = false

    private var grouped: [(LibraryCategory, [LibraryItem])] {
        LibraryCategory.allCases.compactMap { category in
            let matching = items.filter { $0.category == category }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    var body: some View {
        List {
            ForEach(grouped, id: \.0) { category, categoryItems in
                Section(category.displayName) {
                    ForEach(categoryItems) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline.weight(.medium))
                            Text(item.value).font(.caption).foregroundStyle(.secondary)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = item.value
                            } label: {
                                Label("Wert kopieren", systemImage: "doc.on.doc")
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { context.delete(item) } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView("Library ist leer", systemImage: "books.vertical", description: Text("Speichere Hashtag-Gruppen, Links, Credits und mehr für die Wiederverwendung."))
            }
        }
        .navigationTitle("Content Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewItem = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNewItem) {
            NewLibraryItemSheet()
        }
    }
}

private struct NewLibraryItemSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var category: LibraryCategory = .hashtagGroup
    @State private var title = ""
    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Kategorie", selection: $category) {
                    ForEach(LibraryCategory.allCases) { category in
                        Label(category.displayName, systemImage: category.symbol).tag(category)
                    }
                }
                TextField("Titel", text: $title)
                TextField("Wert (Hashtags, Link, Text, Name…)", text: $value, axis: .vertical)
            }
            .navigationTitle("Neuer Eintrag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        context.insert(LibraryItem(category: category, title: title, value: value))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || value.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
