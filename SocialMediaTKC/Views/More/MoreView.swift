import SwiftUI
import SwiftData

/// §26 "Mehr"-Tab. Templates (§11) sind für die MVP-Priorität funktionsfähig;
/// Ideen/Library/Export/Archiv/Einstellungen folgen als spätere Ausbaustufen (siehe Roadmap unten).
struct MoreView: View {
    @Query(sort: \ContentTemplate.title) private var templates: [ContentTemplate]

    var body: some View {
        NavigationStack {
            List {
                Section("Templates") {
                    NavigationLink {
                        TemplateListView()
                    } label: {
                        Label("Content-Templates (\(templates.count))", systemImage: "doc.on.doc")
                    }
                }
                Section("Geplant für die nächste Ausbaustufe") {
                    Label("Ideen (Ungeplant-Bereich)", systemImage: "lightbulb")
                    Label("Content Library", systemImage: "books.vertical")
                    Label("Exporte (PDF/CSV/Excel)", systemImage: "square.and.arrow.up")
                    Label("Veröffentlichungshistorie / Archiv", systemImage: "archivebox")
                    Label("Plattformübersicht", systemImage: "chart.bar")
                    Label("Einstellungen", systemImage: "gearshape")
                }
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Mehr")
        }
    }
}

private struct TemplateListView: View {
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
