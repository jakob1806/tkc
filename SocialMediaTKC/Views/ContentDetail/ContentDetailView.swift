import SwiftUI
import SwiftData

/// Detailansicht eines Content-Eintrags (§6) mit direkt kopierbaren Texten (§7)
/// und optionalem Freigabeprozess (§14).
struct ContentDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: ContentItem
    @State private var showingEditor = false

    var body: some View {
        List {
            Section {
                LabeledContent("Plattform") {
                    Label(item.platform.displayName, systemImage: item.platform.symbol)
                }
                LabeledContent("Typ", value: item.contentType.displayName)
                LabeledContent("Status") {
                    Text(item.status.displayName)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(item.status.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(item.status.color)
                }
                if let publishTime = item.publishTime {
                    LabeledContent("Veröffentlichung", value: publishTime.formatted(date: .abbreviated, time: .shortened))
                }
                if let concert = item.concert {
                    NavigationLink {
                        ConcertDetailView(concert: concert)
                    } label: {
                        LabeledContent("Konzert", value: concert.title)
                    }
                }
                if let assignee = item.assignee, !assignee.isEmpty {
                    LabeledContent("Verantwortlich", value: assignee)
                }
            }

            copyableSection("Caption", text: item.caption)
            copyableSection("Story Text", text: item.storyText)
            copyableSection("Call to Action", text: item.callToAction)
            copyableSection("Hashtags", text: item.hashtags)
            copyableSection("Links", text: item.links)
            copyableSection("Notizen", text: item.notes)

            Section("Aufgaben") {
                TaskChecklistView(item: item)
            }

            Section("Assets") {
                AssetListView(item: item)
            }

            Section("Freigabe") {
                Picker("Status", selection: $item.approvalStatus) {
                    ForEach(ApprovalStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .onChange(of: item.approvalStatus) { _, newValue in
                    if newValue == .approved {
                        item.approvedAt = .now
                        if item.approvedBy == nil || item.approvedBy!.isEmpty {
                            item.approvedBy = item.assignee
                        }
                    }
                }
                if item.approvalStatus == .approved || item.approvalStatus == .requested {
                    TextField("Freigegeben von", text: Binding(
                        get: { item.approvedBy ?? "" },
                        set: { item.approvedBy = $0.isEmpty ? nil : $0 }
                    ))
                    if let approvedAt = item.approvedAt { LabeledContent("Am", value: approvedAt.formatted()) }
                }
                TextField("Kommentar", text: Binding(
                    get: { item.approvalComment ?? "" },
                    set: { item.approvalComment = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ContentEditorView(existingItem: item, concert: item.concert)
        }
    }

    @ViewBuilder
    private func copyableSection(_ title: String, text: String?) -> some View {
        if let text, !text.isEmpty {
            Section(title) {
                Text(text)
                    .textSelection(.enabled)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = text
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                        }
                    }
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("\(title) kopieren", systemImage: "doc.on.doc")
                }
                .font(.caption)
            }
        }
    }
}
