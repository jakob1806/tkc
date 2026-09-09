import SwiftUI
import SwiftData

/// "Mehr"-Tab: Content Studio (bisheriger Contentplaner - jetzt nur noch ein Modul unter vielen),
/// KI, Medien/Kontakte/Finanzen/Dokumente (Ausbaustufen), Auswertungen, Einstellungen.
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

                Section("Content Studio") {
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
                        Label("Content-Templates (\(templates.count))", systemImage: "doc.on.doc")
                    }
                    NavigationLink { ContentLibraryView() } label: {
                        Label("Content Library", systemImage: "books.vertical")
                    }
                    NavigationLink { ExportView() } label: {
                        Label("Exporte", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink { ArchiveView() } label: {
                        Label("Veröffentlichungshistorie / Archiv", systemImage: "archivebox")
                    }
                }

                Section("Auswertungen") {
                    NavigationLink { PlatformOverviewView() } label: {
                        Label("Plattformübersicht", systemImage: "chart.bar")
                    }
                    NavigationLink { PerformanceOverviewView() } label: {
                        Label("Performance", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    NavigationLink { TicketCorrelationView() } label: {
                        Label("Ticket-Korrelation", systemImage: "chart.xyaxis.line")
                    }
                }

                Section {
                    ComingSoonRow(title: "Medien", symbol: "photo.stack", detail: "Zentrales Foto-/Video-/Audioarchiv mit Rechten & Lizenzen")
                    ComingSoonRow(title: "Kontakte (CRM)", symbol: "person.crop.rectangle.stack", detail: "Veranstalter, Agenturen, Dirigenten, Presse")
                    ComingSoonRow(title: "Finanzen", symbol: "eurosign.circle", detail: "Reisebudgets, Projektkosten, Honorare, Spesen")
                    ComingSoonRow(title: "Dokumente", symbol: "doc.text.magnifyingglass", detail: "Verträge, Rider, Reiseunterlagen je Projekt")
                    ComingSoonRow(title: "Repertoire-Archiv", symbol: "music.note.list", detail: "Werke, Noten, Besetzungsanforderungen, Aufführungshistorie")
                } header: {
                    Text("Geplante Module")
                } footer: {
                    Text("Diese Bereiche sind Teil des Choir-Operations-System-Konzepts, aber noch nicht gebaut.")
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
    let detail: String

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
