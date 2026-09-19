import SwiftUI
import SwiftData

/// Detailansicht eines Content-Eintrags (§6) mit direkt kopierbaren Texten (§7)
/// und optionalem Freigabeprozess (§14).
struct ContentDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: ContentItem
    @Query private var allSocialPosts: [SocialPost]
    @State private var showingEditor = false
    @State private var showingDuplicateHint = false
    var settings = AppSettings.shared

    /// §16 Contentplan-Verknüpfung: der Social Post, der auf diesen Content-Eintrag verweist.
    private var linkedSocialPost: SocialPost? {
        allSocialPosts.first { $0.linkedContentItem?.persistentModelID == item.persistentModelID }
    }

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
                if settings.currentRole.canApprove {
                    Picker("Status", selection: $item.approvalStatus) {
                        ForEach(ApprovalStatus.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .onChange(of: item.approvalStatus) { _, newValue in
                        if newValue == .approved {
                            item.approvedAt = .now
                            if item.approvedBy == nil || item.approvedBy!.isEmpty {
                                item.approvedBy = settings.displayName.isEmpty ? item.assignee : settings.displayName
                            }
                        }
                    }
                } else {
                    LabeledContent("Status", value: item.approvalStatus.displayName)
                    if settings.currentRole.canEdit && (item.approvalStatus == .draft || item.approvalStatus == .changesNeeded) {
                        Button {
                            item.approvalStatus = .requested
                            item.updatedAt = .now
                        } label: {
                            Label("Freigabe anfragen", systemImage: "paperplane")
                        }
                    }
                }
                if item.approvalStatus == .approved || item.approvalStatus == .requested {
                    if settings.currentRole.canApprove {
                        TextField("Freigegeben von", text: Binding(
                            get: { item.approvedBy ?? "" },
                            set: { item.approvedBy = $0.isEmpty ? nil : $0 }
                        ))
                    } else if let approvedBy = item.approvedBy {
                        LabeledContent("Freigegeben von", value: approvedBy)
                    }
                    if let approvedAt = item.approvedAt { LabeledContent("Am", value: approvedAt.formatted()) }
                }
                if settings.currentRole.canEdit {
                    TextField("Kommentar", text: Binding(
                        get: { item.approvalComment ?? "" },
                        set: { item.approvalComment = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                } else if let comment = item.approvalComment, !comment.isEmpty {
                    Text(comment)
                }
            }

            Section("Kommentare") {
                CommentThreadView(item: item)
            }

            Section("Performance") {
                if let linkedSocialPost {
                    NavigationLink {
                        SocialPostDetailView(post: linkedSocialPost)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(linkedSocialPost.platform.displayName, systemImage: linkedSocialPost.platform.symbol)
                                .foregroundStyle(linkedSocialPost.platform.color)
                            HStack(spacing: 12) {
                                Text("Views: \(linkedSocialPost.latestSnapshot?.views.map { $0.formatted() } ?? "—")")
                                Text("Likes: \(linkedSocialPost.latestSnapshot?.likes.map { $0.formatted() } ?? "—")")
                            }
                            .font(.caption).foregroundStyle(.secondary)
                            if let lastSync = linkedSocialPost.latestSnapshot?.capturedAt {
                                Text("Letzte Synchronisierung: \(lastSync.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                } else {
                    Text("Noch kein Social Post verknüpft. Verknüpfe einen Post unter Analytics → Post-Detail → Verknüpfung, um hier die echte Performance zu sehen.")
                        .font(.caption).foregroundStyle(.secondary)
                    PerformanceMetricsView(item: item)
                }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if settings.currentRole.canEdit {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showingEditor = true } label: { Label("Bearbeiten", systemImage: "pencil") }
                        Button {
                            item.duplicate(in: context)
                            showingDuplicateHint = true
                        } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Content-Aktionen")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            ContentEditorView(existingItem: item, concert: item.concert)
        }
        .alert("Dupliziert", isPresented: $showingDuplicateHint) {
            Button("OK") {}
        } message: {
            Text("Die Kopie liegt als „Idee“ ohne festes Datum unter Mehr → Ideen.")
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
