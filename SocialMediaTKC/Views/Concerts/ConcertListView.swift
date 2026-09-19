import SwiftUI
import SwiftData

/// §9 Konzertübersicht.
struct ConcertListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Concert.date) private var concerts: [Concert]
    @State private var isSyncing = false
    @State private var syncMessage: String?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !upcoming.isEmpty {
                    Section("Kommende Konzerte") {
                        ForEach(upcoming) { concert in row(concert) }
                    }
                }
                if !past.isEmpty {
                    Section("Vergangene Konzerte") {
                        ForEach(past) { concert in row(concert) }
                    }
                }
            }
            .refreshable { await sync() }
            .themedList()
            .overlay {
                if concerts.isEmpty {
                    ContentUnavailableView("Keine Konzerte", systemImage: "music.mic", description: Text("Tippe auf „Konzerte aktualisieren“, um von toelzerknabenchor.de zu synchronisieren."))
                }
            }
            .navigationTitle("Konzerte")
            .searchable(text: $searchText, prompt: "Titel, Ort, Stadt…")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await sync() }
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Label("Konzerte aktualisieren", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isSyncing)
                }
            }
            .alert("Synchronisation", isPresented: .constant(syncMessage != nil), actions: {
                Button("OK") { syncMessage = nil }
            }, message: {
                Text(syncMessage ?? "")
            })
        }
    }

    private var filteredConcerts: [Concert] {
        guard !searchText.isEmpty else { return concerts }
        return concerts.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText) ||
            $0.venue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var upcoming: [Concert] {
        filteredConcerts.filter { !$0.isPast }.sorted { $0.date < $1.date }
    }

    private var past: [Concert] {
        filteredConcerts.filter { $0.isPast }.sorted { $0.date > $1.date }
    }

    private func row(_ concert: Concert) -> some View {
        NavigationLink {
            ConcertDetailView(concert: concert)
        } label: {
            ConcertRow(concert: concert)
        }
    }

    private func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let result = try await ConcertSyncService.syncNow(context: context)
            syncMessage = "\(result.inserted) neu, \(result.updated) aktualisiert, \(result.unchanged) unverändert."
        } catch {
            syncMessage = "Synchronisation fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

private struct ConcertRow: View {
    let concert: Concert

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DateBadge(date: concert.date, isPast: concert.isPast)

            VStack(alignment: .leading, spacing: 2) {
                Text(concert.title).font(.headline)
                Text("\(concert.startTime.map { $0.formatted(date: .omitted, time: .shortened) + " · " } ?? "")\(concert.venue), \(concert.city)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if !concert.isPast {
                        Text(concert.daysUntilLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                    }
                    Label("\(concert.contentItems.count) Content", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let lastSync = concert.lastSyncedAt {
                    Text("Zuletzt synchronisiert: \(lastSync.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
