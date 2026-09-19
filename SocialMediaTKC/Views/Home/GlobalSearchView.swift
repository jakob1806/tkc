import SwiftUI
import SwiftData

/// Globale Suche über Content, Konzerte und Library.
struct GlobalSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ContentItem.date, order: .reverse) private var content: [ContentItem]
    @Query(sort: \Concert.date) private var concerts: [Concert]
    @Query private var library: [LibraryItem]
    @State private var query = ""

    private var contentHits: [ContentItem] {
        guard !query.isEmpty else { return [] }
        return content.filter { item in
            [item.title, item.caption, item.storyText, item.hashtags, item.notes, item.assignee]
                .contains { $0?.localizedCaseInsensitiveContains(query) == true }
        }
    }

    private var concertHits: [Concert] {
        guard !query.isEmpty else { return [] }
        return concerts.filter { concert in
            [concert.title, concert.venue, concert.city, concert.program, concert.conductor]
                .contains { $0?.localizedCaseInsensitiveContains(query) == true }
        }
    }

    private var libraryHits: [LibraryItem] {
        guard !query.isEmpty else { return [] }
        return library.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.value.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    ContentUnavailableView("Suche", systemImage: "magnifyingglass", description: Text("Durchsucht Content, Konzerte und die Bibliothek."))
                } else if contentHits.isEmpty && concertHits.isEmpty && libraryHits.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
                if !contentHits.isEmpty {
                    Section("Content") {
                        ForEach(contentHits) { item in
                            NavigationLink { ContentDetailView(item: item) } label: {
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                    Text("\(item.platform.displayName) · \(item.status.displayName)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if !concertHits.isEmpty {
                    Section("Konzerte") {
                        ForEach(concertHits) { concert in
                            NavigationLink { ConcertDetailView(concert: concert) } label: {
                                VStack(alignment: .leading) {
                                    Text(concert.title)
                                    Text("\(concert.date.formatted(date: .abbreviated, time: .omitted)) · \(concert.venue), \(concert.city)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if !libraryHits.isEmpty {
                    Section("Bibliothek") {
                        ForEach(libraryHits) { entry in
                            VStack(alignment: .leading) {
                                Text(entry.title)
                                Text(entry.value).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Content, Konzerte, Bibliothek…")
            .navigationTitle("Suche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Schließen") { dismiss() } }
            }
        }
    }
}
