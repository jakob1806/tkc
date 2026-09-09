import SwiftUI
import SwiftData

/// Erstellt oder bearbeitet einen ContentItem-Eintrag (§3 Content erstellen, §6 Detailseite, §7 Texte).
struct ContentEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Concert.date) private var concerts: [Concert]

    /// Vorhandenes Item zum Bearbeiten, oder nil für Neuanlage.
    var existingItem: ContentItem?
    var concert: Concert?
    var startAsIdea: Bool = false

    @State private var title: String
    @State private var date: Date
    @State private var publishTime: Date
    @State private var hasPublishTime: Bool
    @State private var isUnplanned: Bool
    @State private var platform: Platform
    @State private var contentType: ContentType
    @State private var status: ContentStatus
    @State private var priority: Priority
    @State private var assignee: String
    @State private var linkedConcert: Concert?

    @State private var caption: String
    @State private var storyText: String
    @State private var callToAction: String
    @State private var hashtags: String
    @State private var notes: String
    @State private var links: String

    init(existingItem: ContentItem? = nil, concert: Concert?, startAsIdea: Bool = false) {
        self.existingItem = existingItem
        self.concert = concert
        self.startAsIdea = startAsIdea
        _title = State(initialValue: existingItem?.title ?? "")
        _date = State(initialValue: existingItem?.date ?? .now)
        _publishTime = State(initialValue: existingItem?.publishTime ?? .now)
        _hasPublishTime = State(initialValue: existingItem?.publishTime != nil)
        _isUnplanned = State(initialValue: existingItem?.isUnplanned ?? startAsIdea)
        _platform = State(initialValue: existingItem?.platform ?? .instagram)
        _contentType = State(initialValue: existingItem?.contentType ?? .feedPost)
        _status = State(initialValue: existingItem?.status ?? .idea)
        _priority = State(initialValue: existingItem?.priority ?? .medium)
        _assignee = State(initialValue: existingItem?.assignee ?? "")
        _linkedConcert = State(initialValue: existingItem?.concert ?? concert)
        _caption = State(initialValue: existingItem?.caption ?? "")
        _storyText = State(initialValue: existingItem?.storyText ?? "")
        _callToAction = State(initialValue: existingItem?.callToAction ?? "")
        _hashtags = State(initialValue: existingItem?.hashtags ?? "")
        _notes = State(initialValue: existingItem?.notes ?? "")
        _links = State(initialValue: existingItem?.links ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Allgemein") {
                    TextField("Titel", text: $title)
                    Toggle("Als Idee ohne Datum speichern", isOn: $isUnplanned.animation())
                    if !isUnplanned {
                        DatePicker("Datum", selection: $date, displayedComponents: .date)
                        Toggle("Geplante Uhrzeit", isOn: $hasPublishTime.animation())
                        if hasPublishTime {
                            DatePicker("Uhrzeit", selection: $publishTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    Picker("Plattform", selection: $platform) {
                        ForEach(Platform.allCases) { platform in
                            Label(platform.displayName, systemImage: platform.symbol).tag(platform)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Content-Typ", selection: $contentType) {
                        ForEach(ContentType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Status", selection: $status) {
                        ForEach(ContentStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Priorität", selection: $priority) {
                        ForEach(Priority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    TextField("Zuständige Person", text: $assignee)
                }

                Section("Konzert") {
                    Picker("Verbundenes Konzert", selection: $linkedConcert) {
                        Text("Keins").tag(Concert?.none)
                        ForEach(concerts) { concert in
                            Text("\(concert.title) – \(concert.venue)").tag(Concert?.some(concert))
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Texte") {
                    TextField("Caption", text: $caption, axis: .vertical)
                    TextField("Story Text", text: $storyText, axis: .vertical)
                    TextField("Call to Action", text: $callToAction)
                    TextField("Hashtags", text: $hashtags, axis: .vertical)
                }

                Section("Sonstiges") {
                    TextField("Links", text: $links, axis: .vertical)
                    TextField("Notizen", text: $notes, axis: .vertical)
                }

                if let existingItem {
                    Section("Aufgaben") {
                        TaskChecklistView(item: existingItem)
                    }
                    Section("Assets") {
                        AssetListView(item: existingItem)
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "Neuer Content" : "Content bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let resolvedPublishTime: Date? = (isUnplanned || !hasPublishTime) ? nil : publishTime
        let resolvedDate = isUnplanned ? .now : date
        if let existingItem {
            existingItem.title = title
            existingItem.date = resolvedDate
            existingItem.publishTime = resolvedPublishTime
            existingItem.isUnplanned = isUnplanned
            existingItem.platform = platform
            existingItem.contentType = contentType
            existingItem.status = status
            existingItem.priority = priority
            existingItem.assignee = assignee.isEmpty ? nil : assignee
            existingItem.concert = linkedConcert
            existingItem.caption = caption.isEmpty ? nil : caption
            existingItem.storyText = storyText.isEmpty ? nil : storyText
            existingItem.callToAction = callToAction.isEmpty ? nil : callToAction
            existingItem.hashtags = hashtags.isEmpty ? nil : hashtags
            existingItem.notes = notes.isEmpty ? nil : notes
            existingItem.links = links.isEmpty ? nil : links
            existingItem.updatedAt = .now
            // Manuelle Bearbeitung entkoppelt vom automatischen Nachziehen bei Terminverschiebung.
            existingItem.relativeOffset = nil
        } else {
            let item = ContentItem(
                title: title,
                date: resolvedDate,
                publishTime: resolvedPublishTime,
                platform: platform,
                contentType: contentType,
                status: status,
                priority: priority,
                assignee: assignee.isEmpty ? nil : assignee,
                concert: linkedConcert,
                isUnplanned: isUnplanned
            )
            item.caption = caption.isEmpty ? nil : caption
            item.storyText = storyText.isEmpty ? nil : storyText
            item.callToAction = callToAction.isEmpty ? nil : callToAction
            item.hashtags = hashtags.isEmpty ? nil : hashtags
            item.notes = notes.isEmpty ? nil : notes
            item.links = links.isEmpty ? nil : links
            context.insert(item)
        }
        dismiss()
    }
}
