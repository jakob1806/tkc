import SwiftUI
import SwiftData

/// Konzertdetailseite mit "Content rund um dieses Konzert" (§4) und Content-Timeline (§10).
struct ConcertDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var concert: Concert
    @Query private var templates: [ContentTemplate]
    @State private var showingTemplatePicker = false
    @State private var showingNewContent = false

    private var sortedContent: [ContentItem] {
        concert.contentItems.sorted { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Datum", value: concert.date.formatted(date: .long, time: .omitted))
                if let start = concert.startTime {
                    LabeledContent("Uhrzeit", value: start.formatted(date: .omitted, time: .shortened))
                }
                LabeledContent("Ort", value: "\(concert.venue), \(concert.city)")
                if let address = concert.address { LabeledContent("Adresse", value: address) }
                if let conductor = concert.conductor { LabeledContent("Dirigent", value: conductor) }
                if let ensemble = concert.ensemble { LabeledContent("Ensemble", value: ensemble) }
                if let program = concert.program { LabeledContent("Programm", value: program) }
                if let performers = concert.performers { LabeledContent("Mitwirkende", value: performers) }
                if let description = concert.concertDescription {
                    Text(description).font(.callout).foregroundStyle(.secondary)
                }
                if let ticketURL = concert.ticketURL, let url = URL(string: ticketURL) {
                    Link(destination: url) {
                        Label("Tickets", systemImage: "ticket.fill")
                    }
                }
                if let lastSync = concert.lastSyncedAt {
                    Text("Zuletzt synchronisiert: \(lastSync.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Section("Content rund um dieses Konzert") {
                if sortedContent.isEmpty {
                    ContentUnavailableView("Noch kein Content geplant", systemImage: "sparkles")
                } else {
                    ForEach(sortedContent) { item in
                        NavigationLink {
                            ContentDetailView(item: item)
                        } label: {
                            TimelineRow(item: item, concert: concert)
                        }
                    }
                }
                Button {
                    showingTemplatePicker = true
                } label: {
                    Label("Contentplan für Konzert erstellen", systemImage: "wand.and.stars")
                }
                Button {
                    showingNewContent = true
                } label: {
                    Label("Einzelnen Content hinzufügen", systemImage: "plus")
                }
            }
        }
        .navigationTitle(concert.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTemplatePicker) {
            TemplatePickerSheet(concert: concert, templates: templates)
        }
        .sheet(isPresented: $showingNewContent) {
            ContentEditorView(concert: concert)
        }
    }
}

private struct TimelineRow: View {
    let item: ContentItem
    let concert: Concert

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text((item.publishTime ?? item.date).formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.title)
                    .font(.subheadline)
            }
            Spacer()
            Label(item.contentType.displayName, systemImage: item.contentType.symbol)
                .labelStyle(.iconOnly)
                .foregroundStyle(item.platform.color)
            Circle().fill(item.status.color).frame(width: 8, height: 8)
        }
    }
}

private struct TemplatePickerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let concert: Concert
    let templates: [ContentTemplate]

    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button {
                    ContentScheduler.applyTemplate(template, to: concert, context: context)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(template.title).font(.headline)
                        Text("\(template.items.count) Vorschläge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Template wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}
