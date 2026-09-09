import SwiftUI
import SwiftData

/// §20 "Ungeplant"-Bereich: Ideen ohne festes Datum, später einem Kalendertag zuordenbar.
struct IdeasView: View {
    @Environment(\.modelContext) private var context
    @Query private var allItems: [ContentItem]
    @State private var showingNewIdea = false
    @State private var assigningItem: ContentItem?

    private var ideas: [ContentItem] {
        allItems.filter(\.isUnplanned).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            ForEach(ideas) { item in
                HStack {
                    Image(systemName: item.contentType.symbol).foregroundStyle(item.platform.color)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                        if let concert = item.concert {
                            Text(concert.title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Einplanen") { assigningItem = item }
                        .font(.caption)
                        .buttonStyle(.bordered)
                }
                .swipeActions {
                    Button(role: .destructive) { context.delete(item) } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
            .onDelete { indices in
                for index in indices { context.delete(ideas[index]) }
            }
        }
        .overlay {
            if ideas.isEmpty {
                ContentUnavailableView("Keine Ideen", systemImage: "lightbulb", description: Text("Sammle hier Content-Ideen, bevor du sie einem Datum zuordnest."))
            }
        }
        .navigationTitle("Ideen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewIdea = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNewIdea) {
            ContentEditorView(concert: nil, startAsIdea: true)
        }
        .sheet(item: $assigningItem) { item in
            AssignDateSheet(item: item)
        }
    }
}

private struct AssignDateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ContentItem
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Datum", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle("Auf Kalendertag legen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Einplanen") {
                        item.date = date
                        item.publishTime = date
                        item.isUnplanned = false
                        item.status = .planned
                        item.updatedAt = .now
                        dismiss()
                    }
                }
            }
        }
    }
}
