import SwiftUI
import SwiftData

/// §11 Plattformübersicht → komplette Detailanalyse beim Öffnen einer Plattform.
struct PlatformDetailView: View {
    let platform: SocialPlatform
    @Query private var allPosts: [SocialPost]
    @Query private var allAccounts: [SocialAccount]
    @State private var days = 30

    private var posts: [SocialPost] { allPosts.filter { $0.platform == platform } }
    private var accounts: [SocialAccount] { allAccounts.filter { $0.platform == platform } }
    private var range: ClosedRange<Date> {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        return start...Date.now
    }

    var body: some View {
        List {
            Section {
                Picker("Zeitraum", selection: $days) {
                    Text("7 Tage").tag(7)
                    Text("30 Tage").tag(30)
                    Text("90 Tage").tag(90)
                }
                .pickerStyle(.segmented)

                MainAnalyticsChart(posts: allPosts, range: range, metricSelection: [.views], platformSelection: [platform])
                    .frame(height: 220)
            }

            Section("Kennzahlen") {
                ForEach(SocialMetric.primary) { metric in
                    LabeledContent(metric.displayName, value: SocialAnalyticsRepository.total(metric, posts: posts, range: range, mode: .absolute).map { $0.formatted() } ?? "—")
                }
                LabeledContent("Follower", value: accounts.compactMap(\.followerCount).reduce(0, +).formatted())
            }

            Section("Top-Beiträge") {
                ForEach(posts.sorted { ($0.latestSnapshot?.views ?? 0) > ($1.latestSnapshot?.views ?? 0) }.prefix(10)) { post in
                    NavigationLink {
                        SocialPostDetailView(post: post)
                    } label: {
                        Text(post.caption ?? post.postType.displayName)
                    }
                }
            }
        }
        .navigationTitle(platform.displayName)
    }
}
