import SwiftUI
import SwiftData
import Charts

/// §15 Plattform-Vergleich: gemeinsamer Graph + Prozentanteile.
struct PlatformComparisonView: View {
    @Query private var allPosts: [SocialPost]
    @State private var metric: SocialMetric = .views
    @State private var days: Int = 30

    private var range: ClosedRange<Date> {
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        return start...Date.now
    }

    private var shares: [(SocialPlatform, Double)] {
        SocialAnalyticsRepository.platformShare(metric, posts: allPosts, range: range)
    }

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
                    Picker("Zeitraum", selection: $days) {
                        Text("7 Tage").tag(7)
                        Text("30 Tage").tag(30)
                        Text("90 Tage").tag(90)
                    }
                    .pickerStyle(.segmented)

                    Chart {
                        ForEach(SocialPlatform.allCases) { platform in
                            let platformPosts = allPosts.filter { $0.platform == platform }
                            ForEach(SocialAnalyticsRepository.series(metric, posts: platformPosts, range: range)) { point in
                                LineMark(x: .value("Datum", point.date), y: .value(metric.displayName, point.value))
                                    .foregroundStyle(platform.color)
                            }
                        }
                    }
                    .frame(height: 220)
                } header: {
                    Text("Instagram vs. Facebook vs. TikTok vs. YouTube")
                }

                Section("\(metric.displayName) letzte \(days) Tage") {
                    ForEach(shares, id: \.0) { platform, percentage in
                        HStack {
                            Label(platform.displayName, systemImage: platform.symbol).foregroundStyle(platform.color)
                            Spacer()
                            Text(String(format: "%.0f%%", percentage))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Plattform-Vergleich")
        }
    }
}
