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
            .background(Theme.background.ignoresSafeArea())
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
                Text(status.displayName).font(.headline).foregroundStyle(status.color)
                Text("\(items.count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(status.color.opacity(0.18), in: Capsule())
                    .foregroundStyle(status.color)
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
                        .overlay(alignment: .bottomTrailing) {
                            if let next = ContentStatus.boardColumns.next(after: status) {
                                Button {
                                    item.status = next
                                } label: {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(next.color)
                                        .padding(6)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Verschieben nach \(next.displayName)")
                            }
                        }
                        .contextMenu {
                            if let next = ContentStatus.boardColumns.next(after: status) {
                                Button { item.status = next } label: {
                                    Label("Weiter: \(next.displayName)", systemImage: "arrow.right")
                                }
                            }
                            if let previous = ContentStatus.boardColumns.previous(before: status) {
                                Button { item.status = previous } label: {
                                    Label("Zurück: \(previous.displayName)", systemImage: "arrow.left")
                                }
                            }
                            Menu("Verschieben nach") {
                                ForEach(ContentStatus.allCases.filter { $0 != status }) { target in
                                    Button(target.displayName) { item.status = target }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(width: 240)
        .background(status.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                .fill(status.color)
                .frame(height: 4)
        }
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
