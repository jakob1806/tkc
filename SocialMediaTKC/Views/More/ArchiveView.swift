import SwiftUI
import SwiftData

/// §23 Veröffentlichungshistorie: durchsuchbares Archiv veröffentlichter Inhalte.
struct ArchiveView: View {
    @Query(sort: \ContentItem.date, order: .reverse) private var allItems: [ContentItem]
    @State private var searchText = ""

    private var published: [ContentItem] {
        allItems.filter { $0.status == .published }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) || ($0.caption ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(published) { item in
                NavigationLink {
                    ContentDetailView(item: item)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: item.platform.symbol).foregroundStyle(item.platform.color)
                            Text(item.title).font(.headline)
                        }
                        Text((item.publishTime ?? item.date).formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                        if let url = item.publishedURL, !url.isEmpty {
                            Text(url).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                        }
                        if !item.assets.isEmpty {
                            Text("\(item.assets.count) Asset(s)").font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .overlay {
            if published.isEmpty {
                ContentUnavailableView("Noch nichts veröffentlicht", systemImage: "archivebox")
            }
        }
        .searchable(text: $searchText, prompt: "Titel, Caption…")
        .navigationTitle("Archiv")
    }
}
