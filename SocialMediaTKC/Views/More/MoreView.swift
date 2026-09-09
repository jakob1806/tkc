import SwiftUI
import SwiftData

/// "Mehr"-Tab: alles, was keinen eigenen Tab braucht, klar in Gruppen sortiert.
struct MoreView: View {
    @Query(sort: \ContentTemplate.title) private var templates: [ContentTemplate]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { ChorAssistantView() } label: {
                        Label("Chor Assistant", systemImage: "sparkles")
                    }
                }

                Section("Konzerte & Content") {
                    NavigationLink { ConcertListView() } label: {
                        Label("Alle Konzerte", systemImage: "music.mic")
                    }
                    NavigationLink { ContentBoardView() } label: {
                        Label("Board", systemImage: "square.grid.3x3.fill")
                    }
                    NavigationLink { IdeasView() } label: {
                        Label("Ideen", systemImage: "lightbulb")
                    }
                    NavigationLink { TemplateListView() } label: {
                        Label("Content-Templates", systemImage: "doc.on.doc")
                    }
                    NavigationLink { ContentLibraryView() } label: {
                        Label("Content-Bibliothek", systemImage: "books.vertical")
                    }
                    NavigationLink { ArchiveView() } label: {
                        Label("Archiv veröffentlichter Beiträge", systemImage: "archivebox")
                    }
                    NavigationLink { ExportView() } label: {
                        Label("Exportieren", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink { TicketCorrelationView() } label: {
                        Label("Ticket-Auswertung", systemImage: "chart.xyaxis.line")
                    }
                }

                Section("Chor & Besetzung") {
                    NavigationLink { ChoirRosterView() } label: {
                        Label("Sänger verwalten", systemImage: "person.3")
                    }
                }

                Section("Archiv & Ressourcen") {
                    NavigationLink { MediaLibraryView() } label: {
                        Label("Medien", systemImage: "photo.stack")
                    }
                    NavigationLink { DocumentsView() } label: {
                        Label("Dokumente", systemImage: "doc.text.magnifyingglass")
                    }
                }

                Section {
                    ComingSoonRow(title: "Kontakte", symbol: "person.crop.rectangle.stack")
                    ComingSoonRow(title: "Finanzen", symbol: "eurosign.circle")
                    ComingSoonRow(title: "Repertoire-Archiv", symbol: "music.note.list")
                } header: {
                    Text("Noch nicht umgesetzt")
                } footer: {
                    Text("Veranstalter/Agenturen, Reisebudgets/Honorare und ein Werke-Archiv sind als spätere Ausbaustufen vorgesehen.")
                }

                Section {
                    NavigationLink { SettingsView() } label: {
                        Label("Einstellungen", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Mehr")
        }
    }
}

private struct ComingSoonRow: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text("geplant").font(.caption2).foregroundStyle(.tertiary)
        }
        .foregroundStyle(.secondary)
    }
}

struct TemplateListView: View {
    @Query(sort: \ContentTemplate.title) private var templates: [ContentTemplate]

    var body: some View {
        List(templates) { template in
            Section(template.title) {
                ForEach(template.items.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                    HStack {
                        Image(systemName: item.contentType.symbol).foregroundStyle(item.platform.color)
                        Text(item.title)
                        Spacer()
                        Text(offsetLabel(item.offset)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Templates")
    }

    private func offsetLabel(_ offset: RelativeOffset) -> String {
        switch offset.unit {
        case .daysBefore: return "\(offset.days) Tage vorher"
        case .sameDay: return "Konzerttag"
        case .daysAfter: return "\(offset.days) Tage danach"
        }
    }
}
