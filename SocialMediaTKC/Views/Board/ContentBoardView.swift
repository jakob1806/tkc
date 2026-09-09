import SwiftUI
import SwiftData

/// §8 Content Board mit Kanban-Spalten. Karten werden per Swipe (schnell, ein Schritt
/// vor/zurück) oder Kontextmenü (beliebiger Zielstatus) verschoben - echtes Drag & Drop
/// zwischen ScrollViews ist auf iOS ohne Multi-Window-Drop-Target unzuverlässig.
struct ContentBoardView: View {
    @Query(sort: \ContentItem.date) private var allItems: [ContentItem]
    @State private var newContentStatus: ContentStatus?

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(ContentStatus.boardColumns) { status in
                        BoardColumn(
                            status: status,
                            items: allItems.filter { $0.status == status && !$0.isUnplanned },
                            onAdd: { newContentStatus = status }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Board")
            .sheet(item: $newContentStatus) { status in
                ContentEditorView(concert: nil, initialStatus: status)
            }
        }
    }
}

private struct BoardColumn: View {
    @Environment(\.modelContext) private var context
    let status: ContentStatus
    let items: [ContentItem]
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(status.color).frame(width: 8, height: 8)
                Text(status.displayName).font(.headline)
                Text("\(items.count)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(.secondary)
                }
            }
            if items.isEmpty {
                Text("Keine Einträge").font(.caption).foregroundStyle(.tertiary).padding(.top, 4)
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        NavigationLink {
                            ContentDetailView(item: item)
                        } label: {
                            BoardCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Menu("Verschieben nach") {
                                ForEach(ContentStatus.allCases.filter { $0 != status }) { target in
                                    Button(target.displayName) { item.status = target }
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if let next = ContentStatus.boardColumns.next(after: status) {
                                Button {
                                    item.status = next
                                } label: {
                                    Label(next.displayName, systemImage: "arrow.right")
                                }
                                .tint(next.color)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if let previous = ContentStatus.boardColumns.previous(before: status) {
                                Button {
                                    item.status = previous
                                } label: {
                                    Label(previous.displayName, systemImage: "arrow.left")
                                }
                                .tint(previous.color)
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 240)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private extension Array where Element == ContentStatus {
    func next(after status: ContentStatus) -> ContentStatus? {
        guard let index = firstIndex(of: status), index + 1 < count else { return nil }
        return self[index + 1]
    }

    func previous(before status: ContentStatus) -> ContentStatus? {
        guard let index = firstIndex(of: status), index > 0 else { return nil }
        return self[index - 1]
    }
}

private struct BoardCard: View {
    let item: ContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: item.platform.symbol).foregroundStyle(item.platform.color)
                Text(item.platform.displayName).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Spacer()
                if item.priority == .high {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red).font(.caption)
                }
            }
            Text(item.title).font(.subheadline.weight(.medium)).lineLimit(2)
            if let concert = item.concert {
                Text(concert.title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            }
            if let time = item.publishTime {
                Text(time.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }
}
