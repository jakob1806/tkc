import SwiftUI
import SwiftData
import Charts

/// §13 Post-Detailseite: Kennzahlen + Performance-Graph seit Veröffentlichung.
struct SocialPostDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var post: SocialPost
    @Query(sort: \Concert.date) private var concerts: [Concert]
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @Query(sort: \ContentItem.date) private var contentItems: [ContentItem]
    @State private var showingAddSnapshot = false
    @State private var selectedMetric: SocialMetric = .views

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: post.platform.symbol).foregroundStyle(post.platform.color)
                    VStack(alignment: .leading) {
                        Text(post.caption ?? post.postType.displayName)
                        Text(post.publishedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let url = post.externalURL, let link = URL(string: url) {
                    Link("Beitrag öffnen", destination: link)
                }
            }

            Section("Aktueller Stand") {
                metricRow("Views", post.latestSnapshot?.views)
                metricRow("Likes", post.latestSnapshot?.likes)
                metricRow("Kommentare", post.latestSnapshot?.comments)
                metricRow("Shares", post.latestSnapshot?.shares)
                if post.platform == .instagram || post.platform == .facebook {
                    metricRow("Reichweite", post.latestSnapshot?.reach)
                }
                if post.platform == .youtube {
                    if let watchTime = post.latestSnapshot?.watchTimeMinutes {
                        LabeledContent("Watch Time", value: "\(Int(watchTime)) min")
                    } else {
                        LabeledContent("Watch Time", value: "—")
                    }
                }
                if let rate = post.engagementRate {
                    LabeledContent("Engagement Rate", value: String(format: "%.1f%%", rate))
                } else {
                    LabeledContent("Engagement Rate", value: "—")
                }
            }

            Section {
                Picker("Kennzahl", selection: $selectedMetric) {
                    ForEach(SocialMetric.primary) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.segmented)

                if post.snapshots.count < 2 {
                    Text("Mindestens zwei Snapshots nötig, um eine Entwicklung zu zeigen.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Chart(post.sortedSnapshots) { snapshot in
                        if let value = snapshot.value(for: selectedMetric) {
                            LineMark(x: .value("Zeit", snapshot.capturedAt), y: .value(selectedMetric.displayName, value))
                                .foregroundStyle(post.platform.color)
                            PointMark(x: .value("Zeit", snapshot.capturedAt), y: .value(selectedMetric.displayName, value))
                                .foregroundStyle(post.platform.color)
                        }
                    }
                    .frame(height: 200)
                }
            } header: {
                Text("Entwicklung seit Veröffentlichung")
            }

            Section("Verknüpfung") {
                Picker("Content-Eintrag", selection: $post.linkedContentItem) {
                    Text("Keiner").tag(ContentItem?.none)
                    ForEach(contentItems) { item in
                        Text(item.title).tag(ContentItem?.some(item))
                    }
                }
                .pickerStyle(.navigationLink)
                Picker("Konzert", selection: $post.linkedConcert) {
                    Text("Keins").tag(Concert?.none)
                    ForEach(concerts) { concert in
                        Text(concert.title).tag(Concert?.some(concert))
                    }
                }
                .pickerStyle(.navigationLink)
                Picker("Projekt", selection: $post.linkedProject) {
                    Text("Keins").tag(Project?.none)
                    ForEach(projects) { project in
                        Text(project.title).tag(Project?.some(project))
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section {
                Button {
                    showingAddSnapshot = true
                } label: {
                    Label("Neuen Snapshot erfassen", systemImage: "plus")
                }
            }
        }
        .navigationTitle(post.postType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSnapshot) {
            NewSnapshotSheet(post: post)
        }
    }

    private func metricRow(_ title: String, _ value: Int?) -> some View {
        LabeledContent(title, value: value.map(String.init) ?? "—")
    }
}

private struct NewSnapshotSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var post: SocialPost

    @State private var capturedAt = Date.now
    @State private var views = ""
    @State private var likes = ""
    @State private var comments = ""
    @State private var shares = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Zeitpunkt", selection: $capturedAt)
                metricField("Views", text: $views)
                metricField("Likes", text: $likes)
                metricField("Kommentare", text: $comments)
                metricField("Shares", text: $shares)
            }
            .navigationTitle("Neuer Snapshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let snapshot = SocialMetricSnapshot(
                            capturedAt: capturedAt, views: Int(views), likes: Int(likes),
                            comments: Int(comments), shares: Int(shares)
                        )
                        snapshot.post = post
                        context.insert(snapshot)
                        dismiss()
                    }
                }
            }
        }
    }

    private func metricField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("–", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }
}
