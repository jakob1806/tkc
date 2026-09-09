import SwiftUI
import SwiftData

/// §27 Export: Zeitraum, Plattformen und Kennzahlen wählen, als Text/CSV/Share Sheet exportieren.
struct SocialAnalyticsExportView: View {
    @Query private var allPosts: [SocialPost]

    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now)!
    @State private var endDate = Date.now
    @State private var selectedPlatforms: Set<SocialPlatform> = Set(SocialPlatform.allCases)
    @State private var csvURL: SocialIdentifiableURL?

    private var range: ClosedRange<Date> { startDate...endDate }

    private var filteredPosts: [SocialPost] {
        allPosts.filter { selectedPlatforms.contains($0.platform) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeitraum") {
                    DatePicker("Von", selection: $startDate, displayedComponents: .date)
                    DatePicker("Bis", selection: $endDate, displayedComponents: .date)
                }

                Section("Plattformen") {
                    ForEach(SocialPlatform.allCases) { platform in
                        Toggle(platform.displayName, isOn: Binding(
                            get: { selectedPlatforms.contains(platform) },
                            set: { isOn in
                                if isOn { selectedPlatforms.insert(platform) } else { selectedPlatforms.remove(platform) }
                            }
                        ))
                    }
                }

                Section {
                    Button {
                        UIPasteboard.general.string = buildText()
                    } label: {
                        Label("In Zwischenablage kopieren", systemImage: "doc.on.doc")
                    }
                    Button {
                        csvURL = writeTempFile(data: Data(buildCSV().utf8), filename: "Social-Analytics.csv")
                    } label: {
                        Label("Als CSV/Excel exportieren", systemImage: "tablecells")
                    }
                    ShareLink(item: buildText()) {
                        Label("Share Sheet", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Vorschau") {
                    Text(buildText()).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                }
            }
            .navigationTitle("Analytics exportieren")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $csvURL) { boxed in
                SocialShareSheet(activityItems: [boxed.url])
            }
        }
    }

    private func buildText() -> String {
        var lines = ["\(startDate.formatted(date: .abbreviated, time: .omitted)) – \(endDate.formatted(date: .abbreviated, time: .omitted))"]
        for platform in SocialPlatform.allCases where selectedPlatforms.contains(platform) {
            let posts = filteredPosts.filter { $0.platform == platform }
            lines.append("")
            lines.append(platform.displayName)
            for metric in SocialMetric.primary {
                let value = SocialAnalyticsRepository.total(metric, posts: posts, range: range, mode: .absolute)
                lines.append("\(metric.displayName): \(value.map(String.init) ?? "—")")
            }
        }
        let top = filteredPosts.sorted { ($0.latestSnapshot?.views ?? 0) > ($1.latestSnapshot?.views ?? 0) }.prefix(10)
        if !top.isEmpty {
            lines.append("")
            lines.append("Top 10 Posts")
            for post in top {
                lines.append("\(post.platform.displayName) · \(post.caption ?? post.postType.displayName) · \(post.latestSnapshot?.views.map(String.init) ?? "—") Views")
            }
        }
        return lines.joined(separator: "\n")
    }

    private func buildCSV() -> String {
        var rows = [["Plattform", "Kennzahl", "Wert"]]
        for platform in SocialPlatform.allCases where selectedPlatforms.contains(platform) {
            let posts = filteredPosts.filter { $0.platform == platform }
            for metric in SocialMetric.primary {
                let value = SocialAnalyticsRepository.total(metric, posts: posts, range: range, mode: .absolute)
                rows.append([platform.displayName, metric.displayName, value.map(String.init) ?? ""])
            }
        }
        return rows.map { $0.map { "\"\($0)\"" }.joined(separator: ";") }.joined(separator: "\n")
    }

    private func writeTempFile(data: Data, filename: String) -> SocialIdentifiableURL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        return SocialIdentifiableURL(url: url)
    }
}

private struct SocialIdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.path }
}

private struct SocialShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
