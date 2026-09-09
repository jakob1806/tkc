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
                ForEach(filteredConcerts) { concert in
                    NavigationLink {
                        ConcertDetailView(concert: concert)
                    } label: {
                        ConcertRow(concert: concert)
                    }
                }
            }
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

    private func sync() async {
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
            VStack {
                Text(concert.date.formatted(.dateTime.day()))
                    .font(.title2.bold())
                Text(concert.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .textCase(.uppercase)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(concert.title).font(.headline)
                Text("\(concert.venue), \(concert.city)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if !concert.isPast {
                        Text(concert.daysUntil == 0 ? "Heute" : "in \(concert.daysUntil) Tagen")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Text("\(concert.contentItems.count) Content Items geplant")
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
