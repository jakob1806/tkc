import SwiftUI
import SwiftData

/// §8 Content Board mit Kanban-Spalten. Karten werden per Menü zwischen Spalten verschoben
/// (Drag & Drop zwischen Spalten ist auf iOS ohne Multi-Window-Drop-Target unzuverlässig,
/// daher zusätzlich per Context-Menu/Swipe - robuster für den täglichen Gebrauch).
struct ContentBoardView: View {
    @Query(sort: \ContentItem.date) private var allItems: [ContentItem]

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(ContentStatus.boardColumns) { status in
                        BoardColumn(status: status, items: allItems.filter { $0.status == status && !$0.isUnplanned })
                    }
                }
                .padding()
            }
            .navigationTitle("Board")
        }
    }
}

private struct BoardColumn: View {
    @Environment(\.modelContext) private var context
    let status: ContentStatus
    let items: [ContentItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(status.color).frame(width: 8, height: 8)
                Text(status.displayName).font(.headline)
                Text("\(items.count)").font(.caption).foregroundStyle(.secondary)
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
                                ForEach(ContentStatus.allCases) { target in
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct BoardCard: View {
    let item: ContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: item.platform.symbol).foregroundStyle(item.platform.color)
                Text(item.platform.displayName).font(.caption).foregroundStyle(.secondary)
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
