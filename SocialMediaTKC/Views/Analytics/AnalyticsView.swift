import SwiftUI
import SwiftData
import Charts

/// Social Analytics Dashboard (§6-§11): Instagram, Facebook, TikTok, YouTube in einer
/// Oberfläche. Drei Analysearten werden vom selben Hauptdiagramm abgedeckt, indem Kennzahl
/// und Plattform unabhängig wählbar sind (§8/§29 - eine Kennzahl über alle Plattformen,
/// eine Kennzahl einer Plattform, oder alle Kennzahlen einer Plattform).
struct AnalyticsView: View {
    @Query private var allPosts: [SocialPost]
    @Query private var accounts: [SocialAccount]

    private enum TimeRange: String, CaseIterable, Identifiable {
        case sevenDays, thirtyDays, ninetyDays, oneYear
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .sevenDays: return "7 Tage"
            case .thirtyDays: return "30 Tage"
            case .ninetyDays: return "90 Tage"
            case .oneYear: return "1 Jahr"
            }
        }
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            case .oneYear: return 365
            }
        }
    }

    private enum MetricSelection: Hashable {
        case single(SocialMetric)
        case all
    }

    private enum PlatformSelection: Hashable {
        case all
        case one(SocialPlatform)
    }

    @State private var timeRange: TimeRange = .thirtyDays
    @State private var metricSelection: MetricSelection = .single(.views)
    @State private var platformSelection: PlatformSelection = .all
    @State private var valueMode: SocialAnalyticsRepository.ValueMode = .absolute

    private var range: ClosedRange<Date> {
        let start = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: .now)!
        return start...Date.now
    }

    private var connectedAccounts: [SocialAccount] { accounts.filter(\.connected) }
    private var hasAnyData: Bool { !allPosts.isEmpty }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Zeitraum", selection: $timeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowSeparator(.hidden)

                if !hasAnyData {
                    ContentUnavailableView(
                        "Noch keine Social-Analytics-Daten",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Verbinde Accounts und erfasse Posts, um Auswertungen zu sehen.")
                    )
                    Section {
                        NavigationLink { ManageSocialAccountsView() } label: {
                            Label("Social Accounts einrichten", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                } else {
                    kpiSection
                    chartSection
                    platformOverviewSection
                    topContentSection
                    toolsSection
                }
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: - KPI-Karten (§6)

    private var kpiSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                kpiCard("Views", metric: .views)
                kpiCard("Likes", metric: .likes)
                kpiCard("Kommentare", metric: .comments)
                kpiCard("Shares", metric: .shares)
            }
            .padding(.vertical, 4)
        }
    }

    private func kpiCard(_ title: String, metric: SocialMetric) -> some View {
        let absolute = SocialAnalyticsRepository.total(metric, posts: allPosts, range: range, mode: .absolute)
        let growth = SocialAnalyticsRepository.total(metric, posts: allPosts, range: range, mode: .growth)
        return VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(absolute.map { $0.formatted() } ?? "—").font(.title2.bold())
            if let growth {
                Text(growth >= 0 ? "+\(growth.formatted())" : growth.formatted())
                    .font(.caption).foregroundStyle(growth >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Hauptdiagramm (§7, §8, §9)

    private var chartSection: some View {
        Section {
            Picker("Kennzahl", selection: $metricSelection) {
                ForEach(SocialMetric.primary) { Text($0.displayName).tag(MetricSelection.single($0)) }
                Text("Alle Kennzahlen").tag(MetricSelection.all)
            }
            .pickerStyle(.menu)

            Picker("Plattform", selection: $platformSelection) {
                Text("Alle Plattformen").tag(PlatformSelection.all)
                ForEach(SocialPlatform.allCases) { Text($0.displayName).tag(PlatformSelection.one($0)) }
            }
            .pickerStyle(.menu)

            Picker("Darstellung", selection: $valueMode) {
                Text("Absolute Werte").tag(SocialAnalyticsRepository.ValueMode.absolute)
                Text("Wachstum").tag(SocialAnalyticsRepository.ValueMode.growth)
            }
            .pickerStyle(.segmented)

            MainAnalyticsChart(
                posts: allPosts,
                range: range,
                metricSelection: chartMetrics,
                platformSelection: chartPlatforms
            )
            .frame(height: 260)
        } header: {
            Text("Entwicklung")
        }
    }

    private var chartMetrics: [SocialMetric] {
        switch metricSelection {
        case .single(let metric): return [metric]
        case .all: return SocialMetric.primary
        }
    }

    private var chartPlatforms: [SocialPlatform] {
        switch platformSelection {
        case .all: return SocialPlatform.allCases
        case .one(let platform): return [platform]
        }
    }

    // MARK: - Plattformübersicht (§11)

    private var platformOverviewSection: some View {
        Section("Plattformen") {
            ForEach(SocialPlatform.allCases) { platform in
                NavigationLink {
                    PlatformDetailView(platform: platform)
                } label: {
                    PlatformSummaryRow(platform: platform, posts: allPosts.filter { $0.platform == platform }, range: range)
                }
            }
        }
    }

    // MARK: - Top Content (§24)

    private var topContentSection: some View {
        Section("Top Content") {
            ForEach(allPosts.sorted { ($0.latestSnapshot?.views ?? 0) > ($1.latestSnapshot?.views ?? 0) }.prefix(5)) { post in
                NavigationLink {
                    SocialPostDetailView(post: post)
                } label: {
                    HStack {
                        Image(systemName: post.platform.symbol).foregroundStyle(post.platform.color)
                        VStack(alignment: .leading) {
                            Text(post.caption ?? post.postType.displayName).lineLimit(1)
                            Text("\(post.latestSnapshot?.views.map { $0.formatted() } ?? "—") Views · \(post.latestSnapshot?.likes.map { $0.formatted() } ?? "—") Likes")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if SocialAnalyticsRepository.isTrending(post, allPosts: allPosts) {
                            Spacer()
                            Label("Trending", systemImage: "flame.fill")
                                .font(.caption2).foregroundStyle(.orange)
                        }
                    }
                }
            }
        }
    }

    private var toolsSection: some View {
        Section {
            NavigationLink { ContentPerformanceView() } label: {
                Label("Alle Posts (Content Performance)", systemImage: "list.bullet.rectangle")
            }
            NavigationLink { PlatformComparisonView() } label: {
                Label("Plattformen vergleichen", systemImage: "chart.bar.xaxis")
            }
            NavigationLink { FollowerGrowthView() } label: {
                Label("Followerentwicklung", systemImage: "person.2.wave.2")
            }
            NavigationLink { ManageSocialAccountsView() } label: {
                Label("Social Accounts", systemImage: "person.crop.circle.badge.checkmark")
            }
            NavigationLink { SocialAnalyticsExportView() } label: {
                Label("Exportieren", systemImage: "square.and.arrow.up")
            }
        }
    }
}

private struct PlatformSummaryRow: View {
    let platform: SocialPlatform
    let posts: [SocialPost]
    let range: ClosedRange<Date>

    var body: some View {
        HStack {
            Image(systemName: platform.symbol).foregroundStyle(platform.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(platform.displayName)
                Text("\(posts.count) Posts").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let views = SocialAnalyticsRepository.total(.views, posts: posts, range: range, mode: .absolute) {
                Text("\(views.formatted()) Views").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("—").foregroundStyle(.secondary)
            }
        }
    }
}
