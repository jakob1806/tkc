import SwiftUI
import SwiftData
import Charts

/// "Analyse"-Tab: wertet Aufrufe, Likes, Kommentare, Shares und Saves je Plattform aus.
///
/// Die Werte kommen aktuell aus der manuellen Eingabe am Content-Eintrag (§24). Ein
/// automatischer Abruf direkt von Instagram/TikTok/YouTube ist technisch möglich, braucht
/// aber pro Plattform eine eigene OAuth-Anbindung (Meta Graph API, YouTube Data API,
/// TikTok API) inkl. App-Freigabe durch die jeweilige Plattform - das ist ein eigenes
/// Ausbau-Projekt und hier bewusst nicht simuliert.
struct AnalyticsView: View {
    @Query private var allItems: [ContentItem]
    @State private var selectedMetric: Metric = .views

    private enum Metric: String, CaseIterable, Identifiable {
        case views, likes, comments, shares, saves

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .views: return "Views"
            case .likes: return "Likes"
            case .comments: return "Kommentare"
            case .shares: return "Shares"
            case .saves: return "Saves"
            }
        }

        func value(for item: ContentItem) -> Int {
            switch self {
            case .views: return item.metricViews ?? 0
            case .likes: return item.metricLikes ?? 0
            case .comments: return item.metricComments ?? 0
            case .shares: return item.metricShares ?? 0
            case .saves: return item.metricSaves ?? 0
            }
        }
    }

    private var itemsWithMetrics: [ContentItem] { allItems.filter(\.hasMetrics) }

    private struct PlatformTotal: Identifiable {
        let platform: Platform
        let total: Int
        var id: String { platform.id }
    }

    private var totalsByPlatform: [PlatformTotal] {
        Dictionary(grouping: itemsWithMetrics, by: \.platform).compactMap { platform, items in
            let total = items.reduce(0) { $0 + selectedMetric.value(for: $1) }
            return total > 0 ? PlatformTotal(platform: platform, total: total) : nil
        }.sorted { $0.total > $1.total }
    }

    private var plannedByPlatform: [(Platform, Int)] {
        Platform.allCases.map { platform in
            (platform, allItems.filter { $0.platform == platform && !$0.isUnplanned }.count)
        }
    }

    private var maxPlanned: Int { max(plannedByPlatform.map(\.1).max() ?? 1, 1) }

    var body: some View {
        NavigationStack {
            List {
                if itemsWithMetrics.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Kennzahlen erfasst",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Trage bei veröffentlichten Beiträgen Views, Likes, Kommentare etc. im Content-Detail ein, um hier Auswertungen zu sehen.")
                    )
                } else {
                    Section {
                        Picker("Kennzahl", selection: $selectedMetric) {
                            ForEach(Metric.allCases) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)

                        Chart(totalsByPlatform) { row in
                            BarMark(x: .value(selectedMetric.displayName, row.total), y: .value("Plattform", row.platform.displayName))
                                .foregroundStyle(row.platform.color)
                        }
                        .frame(height: CGFloat(totalsByPlatform.count) * 36 + 20)
                    } header: {
                        Text("\(selectedMetric.displayName) je Plattform")
                    }

                    Section("Top-Beiträge nach Engagement") {
                        ForEach(itemsWithMetrics.sorted(by: { $0.engagementScore > $1.engagementScore }).prefix(5)) { item in
                            NavigationLink {
                                ContentDetailView(item: item)
                            } label: {
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

                Section {
                    ForEach(plannedByPlatform, id: \.0) { platform, count in
                        HStack {
                            Label(platform.displayName, systemImage: platform.symbol).foregroundStyle(platform.color)
                            Spacer()
                            Text("\(count) geplant").font(.subheadline).foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(platform.color.opacity(0.25))
                                .frame(width: geo.size.width, height: 6)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(platform.color)
                                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxPlanned), height: 6)
                                }
                        }
                        .frame(height: 6)
                        .padding(.bottom, 4)
                    }
                } header: {
                    Text("Geplanter Content je Plattform")
                } footer: {
                    Text("Automatischer Abruf direkt von den Plattformen ist noch nicht angebunden - Kennzahlen aktuell manuell im Content-Detail erfassen.")
                }
            }
            .navigationTitle("Analyse")
        }
    }
}
