import SwiftUI
import SwiftData

/// §26 "Mehr"-Tab: Ideen, Templates, Library, Exporte, Archiv, Plattformübersicht, Einstellungen.
struct MoreView: View {
    @Query(sort: \ContentTemplate.title) private var templates: [ContentTemplate]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { IdeasView() } label: {
                        Label("Ideen", systemImage: "lightbulb")
                    }
                    NavigationLink { TemplateListView() } label: {
                        Label("Content-Templates (\(templates.count))", systemImage: "doc.on.doc")
                    }
                    NavigationLink { ContentLibraryView() } label: {
                        Label("Content Library", systemImage: "books.vertical")
                    }
                }
                Section {
                    NavigationLink { ExportView() } label: {
                        Label("Exporte", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink { ArchiveView() } label: {
                        Label("Veröffentlichungshistorie / Archiv", systemImage: "archivebox")
                    }
                    NavigationLink { PlatformOverviewView() } label: {
                        Label("Plattformübersicht", systemImage: "chart.bar")
                    }
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
