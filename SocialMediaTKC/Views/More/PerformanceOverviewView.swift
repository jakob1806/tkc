import SwiftUI
import SwiftData
import Charts

/// §24 Performance-Auswertung: "Welche Arten von Konzert-Content funktionieren besonders gut?"
struct PerformanceOverviewView: View {
    @Query private var allItems: [ContentItem]

    private var itemsWithMetrics: [ContentItem] {
        allItems.filter(\.hasMetrics)
    }

    private struct PlatformAverage: Identifiable {
        let platform: Platform
        let averageEngagement: Double
        var id: String { platform.id }
    }

    private struct TypeAverage: Identifiable {
        let type: ContentType
        let averageEngagement: Double
        var id: String { type.id }
    }

    private var byPlatform: [PlatformAverage] {
        Dictionary(grouping: itemsWithMetrics, by: \.platform).compactMap { platform, items in
            guard !items.isEmpty else { return nil }
            let avg = Double(items.reduce(0) { $0 + $1.engagementScore }) / Double(items.count)
            return PlatformAverage(platform: platform, averageEngagement: avg)
        }.sorted { $0.averageEngagement > $1.averageEngagement }
    }

    private var byContentType: [TypeAverage] {
        Dictionary(grouping: itemsWithMetrics, by: \.contentType).compactMap { type, items in
            guard !items.isEmpty else { return nil }
            let avg = Double(items.reduce(0) { $0 + $1.engagementScore }) / Double(items.count)
            return TypeAverage(type: type, averageEngagement: avg)
        }.sorted { $0.averageEngagement > $1.averageEngagement }
    }

    var body: some View {
        List {
            if itemsWithMetrics.isEmpty {
                ContentUnavailableView(
                    "Noch keine Kennzahlen erfasst",
                    systemImage: "chart.bar",
                    description: Text("Trage bei veröffentlichten Beiträgen Views, Likes, Kommentare etc. ein, um Auswertungen zu sehen.")
                )
            } else {
                Section("Ø Engagement je Plattform") {
                    Chart(byPlatform) { row in
                        BarMark(x: .value("Engagement", row.averageEngagement), y: .value("Plattform", row.platform.displayName))
                            .foregroundStyle(row.platform.color)
                    }
                    .frame(height: CGFloat(byPlatform.count) * 36 + 20)
                }

                Section("Ø Engagement je Content-Typ") {
                    Chart(byContentType) { row in
                        BarMark(x: .value("Engagement", row.averageEngagement), y: .value("Typ", row.type.displayName))
                            .foregroundStyle(.indigo)
                    }
                    .frame(height: CGFloat(byContentType.count) * 36 + 20)
                }

                Section("Top-Beiträge") {
                    ForEach(itemsWithMetrics.sorted(by: { $0.engagementScore > $1.engagementScore }).prefix(5)) { item in
                        HStack {
                            Image(systemName: item.contentType.symbol).foregroundStyle(item.platform.color)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                Text("\(item.metricViews ?? 0) Views · \(item.engagementScore) Engagement")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Performance")
    }
}
