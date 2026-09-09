import SwiftUI
import Charts

/// §14 Vergleich mehrerer Posts, normalisiert nach Stunden seit Veröffentlichung, damit
/// Posts von unterschiedlichen Tagen fair vergleichbar sind.
struct PostComparisonView: View {
    let posts: [SocialPost]
    @State private var metric: SocialMetric = .views

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Kennzahl", selection: $metric) {
                        ForEach(SocialMetric.primary) { metric in
                            Text(metric.displayName).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)

                    Chart {
                        ForEach(posts, id: \.persistentModelID) { post in
                            ForEach(seriesFor(post)) { point in
                                LineMark(
                                    x: .value("Stunden seit Veröffentlichung", point.hoursSincePublish),
                                    y: .value(metric.displayName, point.value)
                                )
                                .foregroundStyle(by: .value("Post", label(for: post)))
                            }
                        }
                    }
                    .chartXAxisLabel("Stunden seit Veröffentlichung")
                    .frame(height: 260)
                } header: {
                    Text("\(posts.count) Posts im Vergleich")
                }

                Section("Legende") {
                    ForEach(posts, id: \.persistentModelID) { post in
                        HStack {
                            Image(systemName: post.platform.symbol).foregroundStyle(post.platform.color)
                            Text(label(for: post))
                        }
                    }
                }
            }
            .navigationTitle("Vergleich")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func seriesFor(_ post: SocialPost) -> [SocialAnalyticsRepository.NormalizedPoint] {
        SocialAnalyticsRepository.normalizedSeries(metric, posts: [post])
    }

    private func label(for post: SocialPost) -> String {
        String("\(post.platform.displayName): \(post.caption ?? post.postType.displayName)".prefix(30))
    }
}
