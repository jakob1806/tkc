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
                        ThemedLabel(title: "Chor Assistant", symbol: "sparkles", color: .purple)
                    }
                }

                Section("Konzerte & Content") {
                    NavigationLink { ConcertListView() } label: {
                        ThemedLabel(title: "Alle Konzerte", symbol: "music.mic", color: Theme.brand)
                    }
                    NavigationLink { ContentBoardView() } label: {
                        ThemedLabel(title: "Board", symbol: "square.grid.3x3.fill", color: .blue)
                    }
                    NavigationLink { IdeasView() } label: {
                        ThemedLabel(title: "Ideen", symbol: "lightbulb.fill", color: Theme.gold)
                    }
                    NavigationLink { TemplateListView() } label: {
                        ThemedLabel(title: "Content-Templates", symbol: "doc.on.doc.fill", color: .teal)
                    }
                    NavigationLink { ContentLibraryView() } label: {
                        ThemedLabel(title: "Content-Bibliothek", symbol: "books.vertical.fill", color: .indigo)
                    }
                    NavigationLink { ArchiveView() } label: {
                        ThemedLabel(title: "Archiv veröffentlichter Beiträge", symbol: "archivebox.fill", color: .brown)
                    }
                    NavigationLink { ExportView() } label: {
                        ThemedLabel(title: "Exportieren", symbol: "square.and.arrow.up.fill", color: .green)
                    }
                    NavigationLink { TicketCorrelationView() } label: {
                        ThemedLabel(title: "Ticket-Auswertung", symbol: "chart.xyaxis.line", color: .orange)
                    }
                }

                Section("Chor & Besetzung") {
                    NavigationLink { ChoirRosterView() } label: {
                        ThemedLabel(title: "Sänger verwalten", symbol: "person.3.fill", color: .pink)
                    }
                }

                Section("Archiv & Ressourcen") {
                    NavigationLink { MediaLibraryView() } label: {
                        ThemedLabel(title: "Medien", symbol: "photo.stack.fill", color: .cyan)
                    }
                    NavigationLink { DocumentsView() } label: {
                        ThemedLabel(title: "Dokumente", symbol: "doc.text.fill", color: .mint)
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
                        ThemedLabel(title: "Einstellungen", symbol: "gearshape.fill", color: .gray)
                    }
                }
            }
            .themedList()
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
