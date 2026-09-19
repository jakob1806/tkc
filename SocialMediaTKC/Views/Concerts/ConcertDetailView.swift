import SwiftUI
import SwiftData

/// Konzertdetailseite mit "Content rund um dieses Konzert" (§4) und Content-Timeline (§10).
struct ConcertDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var concert: Concert
    @Query private var templates: [ContentTemplate]
    @Query private var allSocialPosts: [SocialPost]
    @State private var showingTemplatePicker = false
    @State private var showingNewContent = false
    @State private var showingEdit = false
    @State private var confirmDelete = false
    var settings = AppSettings.shared

    private var sortedContent: [ContentItem] {
        concert.contentItems.sorted { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) }
    }

    /// §17 Social Performance eines Konzerts: alle verknüpften Social Posts, je Plattform summiert.
    private var linkedSocialPosts: [SocialPost] {
        allSocialPosts.filter { $0.linkedConcert?.persistentModelID == concert.persistentModelID }
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

            Section {
                HStack {
                    Text("Verkaufte Tickets")
                    Spacer()
                    TextField("–", text: Binding(
                        get: { concert.ticketsSold.map(String.init) ?? "" },
                        set: { concert.ticketsSold = Int($0) }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                }
                HStack {
                    Text("Kapazität")
                    Spacer()
                    TextField("–", text: Binding(
                        get: { concert.venueCapacity.map(String.init) ?? "" },
                        set: { concert.venueCapacity = Int($0) }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                }
                if let rate = concert.occupancyRate {
                    LabeledContent("Auslastung", value: "\(Int(rate * 100))%")
                }
            } footer: {
                Text("Manuell aus dem Ticketing-Report - Grundlage für die Content-Timing-Korrelation (Mehr → Ticket-Korrelation).")
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

            if !linkedSocialPosts.isEmpty {
                Section("Social Performance") {
                    ForEach(SocialPlatform.allCases) { platform in
                        let posts = linkedSocialPosts.filter { $0.platform == platform }
                        if !posts.isEmpty {
                            let views = posts.compactMap { $0.latestSnapshot?.views }.reduce(0, +)
                            LabeledContent {
                                Text("\(views.formatted()) Views")
                            } label: {
                                Label(platform.displayName, systemImage: platform.symbol).foregroundStyle(platform.color)
                            }
                        }
                    }
                    let totalViews = linkedSocialPosts.compactMap { $0.latestSnapshot?.views }.reduce(0, +)
                    LabeledContent("Gesamt", value: "\(totalViews.formatted()) Views · \(linkedSocialPosts.count) Posts")
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
        .sheet(isPresented: $showingEdit) {
            ConcertEditSheet(concert: concert)
        }
        .toolbar {
            if settings.currentRole.canEdit {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showingEdit = true } label: { Label("Bearbeiten", systemImage: "pencil") }
                        if concert.isManuallyEdited {
                            Button {
                                concert.isManuallyEdited = false
                            } label: { Label("Wieder mit Website synchronisieren", systemImage: "arrow.triangle.2.circlepath") }
                        }
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Konzert löschen", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Konzert-Aktionen")
                }
            }
        }
        .confirmationDialog("Konzert löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                ConcertSyncService.markDeleted(externalId: concert.externalId)
                context.delete(concert)
                dismiss()
            }
        } message: {
            Text("Geplanter Content bleibt erhalten, verliert aber die Konzert-Verknüpfung. Das Konzert wird beim Sync nicht neu angelegt.")
        }
    }
}

private struct ConcertEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var concert: Concert
    @State private var originalDate: Date?

    private func optional(_ keyPath: ReferenceWritableKeyPath<Concert, String?>) -> Binding<String> {
        Binding(
            get: { concert[keyPath: keyPath] ?? "" },
            set: { concert[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Grunddaten") {
                    TextField("Titel", text: $concert.title)
                    DatePicker("Beginn", selection: Binding(
                        get: { concert.startTime ?? concert.date },
                        set: { concert.date = $0; concert.startTime = $0 }
                    ))
                    TextField("Veranstaltungsort", text: $concert.venue)
                    TextField("Stadt", text: $concert.city)
                    TextField("Adresse", text: optional(\.address))
                }
                Section("Programm & Mitwirkende") {
                    TextField("Dirigent", text: optional(\.conductor))
                    TextField("Ensemble", text: optional(\.ensemble))
                    TextField("Programm", text: optional(\.program), axis: .vertical)
                    TextField("Mitwirkende", text: optional(\.performers), axis: .vertical)
                    TextField("Beschreibung", text: optional(\.concertDescription), axis: .vertical)
                }
                Section("Tickets") {
                    TextField("Ticket-Link", text: optional(\.ticketURL))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Konzert bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { originalDate = concert.date }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        concert.isManuallyEdited = true
                        if let originalDate, originalDate != concert.date {
                            ContentScheduler.resyncRelativeContent(for: concert)
                        }
                        dismiss()
                    }
                }
            }
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
