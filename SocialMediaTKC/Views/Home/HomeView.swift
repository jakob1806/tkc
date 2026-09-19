import SwiftUI
import SwiftData

/// §15 Dashboard + §16 Intelligente Warnungen, erweitert zum persönlichen Operations-Dashboard
/// (Choir-Operations-Konzept): zeigt zusätzlich den heutigen Tourtag, falls die App gerade
/// während einer Reise genutzt wird.
struct HomeView: View {
    @Query(sort: \ContentItem.date) private var allContent: [ContentItem]
    @Query(sort: \Concert.date) private var allConcerts: [Concert]
    @Query private var allTourDays: [TourDay]
    @State private var showingAssistant = false
    @State private var showingSearch = false

    private let calendar = Calendar.current

    private var activeTourDay: TourDay? {
        allTourDays.first { calendar.isDateInToday($0.date) }
    }

    private var todayItems: [ContentItem] {
        allContent.filter { !$0.isUnplanned && calendar.isDateInToday($0.publishTime ?? $0.date) }
    }

    private var upcomingItems: [ContentItem] {
        allContent.filter {
            guard !$0.isUnplanned else { return false }
            let date = $0.publishTime ?? $0.date
            return date > .now && date <= calendar.date(byAdding: .day, value: 7, to: .now)!
        }
    }

    private var upcomingConcerts: [Concert] {
        allConcerts.filter { !$0.isPast }.sorted { $0.date < $1.date }.prefix(5).map { $0 }
    }

    private var warnings: [Warning] {
        var out: [Warning] = []
        for concert in ContentScheduler.concertsWithoutContentSoon(concerts: allConcerts) {
            out.append(Warning(icon: "exclamationmark.triangle.fill", color: .red, text: "\(concert.title) ist \(concert.daysUntilLabel.lowercased()), aber noch ohne geplanten Content."))
        }
        for concert in ContentScheduler.concertsTomorrowWithoutStory(concerts: allConcerts) {
            out.append(Warning(icon: "exclamationmark.triangle.fill", color: .orange, text: "\(concert.title) ist morgen, aber noch keine Story geplant."))
        }
        for item in allContent where item.isOverdue {
            out.append(Warning(icon: "clock.badge.exclamationmark", color: .red, text: "„\(item.title)“ sollte bereits veröffentlicht sein."))
        }
        for item in allContent where item.isMissingCaption && item.status.needsPreparationWarnings {
            out.append(Warning(icon: "text.badge.xmark", color: .orange, text: "„\(item.title)“ hat noch keine Caption."))
        }
        for item in allContent where item.isMissingAsset && item.status.needsPreparationWarnings {
            out.append(Warning(icon: "photo.badge.exclamationmark", color: .orange, text: "„\(item.title)“ hat noch kein Asset."))
        }
        for item in allContent where item.isLongPendingApproval {
            out.append(Warning(icon: "hourglass", color: .yellow, text: "„\(item.title)“ wartet lange auf Freigabe."))
        }
        for pair in ContentScheduler.itemsTooClose(items: allContent) {
            out.append(Warning(icon: "arrow.left.and.right", color: .purple, text: "„\(pair.0.title)“ und „\(pair.1.title)“ liegen sehr nah beieinander."))
        }
        return out
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HeroCard(
                        concert: upcomingConcerts.first,
                        todayCount: todayItems.count,
                        weekCount: upcomingItems.count,
                        warningCount: warnings.count
                    )
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if let activeTourDay {
                    Section("Auf Tour") {
                        NavigationLink {
                            LiveTourDayView(day: activeTourDay)
                        } label: {
                            Label("Live-Tourmodus · \(activeTourDay.cityOrLocation)", systemImage: "bus")
                        }
                    }
                }

                Section {
                    if todayItems.isEmpty {
                        Text("Heute muss nichts veröffentlicht werden.").foregroundStyle(.secondary)
                    } else {
                        ForEach(todayItems) { item in
                            NavigationLink { ContentDetailView(item: item) } label: { ContentRow(item: item) }
                        }
                    }
                } header: { SectionTitle("Heute", symbol: "sun.max.fill", color: Theme.gold) }

                Section {
                    if upcomingItems.isEmpty {
                        Text("Nichts in den nächsten 7 Tagen geplant.").foregroundStyle(.secondary)
                    } else {
                        ForEach(upcomingItems) { item in
                            NavigationLink { ContentDetailView(item: item) } label: { ContentRow(item: item) }
                        }
                    }
                } header: { SectionTitle("Demnächst (7 Tage)", symbol: "calendar.badge.clock", color: .blue) }

                Section {
                    ForEach(upcomingConcerts) { concert in
                        NavigationLink { ConcertDetailView(concert: concert) } label: {
                            HStack(spacing: 12) {
                                DateBadge(date: concert.date)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(concert.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                                    Text(concert.city).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(concert.daysUntilLabel)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Theme.gold.opacity(0.18), in: Capsule())
                                    .foregroundStyle(Theme.gold)
                            }
                        }
                    }
                } header: { SectionTitle("Kommende Konzerte", symbol: "music.mic", color: Theme.brand) }

                if !warnings.isEmpty {
                    Section {
                        ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in
                            Label(warning.text, systemImage: warning.icon)
                                .foregroundStyle(warning.color)
                                .font(.subheadline)
                        }
                    } header: { SectionTitle("Hinweise", symbol: "exclamationmark.bubble.fill", color: .orange) }
                }

                Section {
                    StatusSummaryView(items: allContent)
                } header: { SectionTitle("Content Status", symbol: "chart.bar.fill", color: .purple) }
            }
            .themedList()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSearch = true } label: { Image(systemName: "magnifyingglass") }
                        .accessibilityLabel("Suche")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAssistant = true } label: { Image(systemName: "sparkles") }
                        .accessibilityLabel("Chor-Assistent")
                }
            }
            .sheet(isPresented: $showingAssistant) {
                ChorAssistantView()
            }
            .sheet(isPresented: $showingSearch) {
                GlobalSearchView()
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let symbol: String
    let color: Color

    init(_ title: String, symbol: String, color: Color) {
        self.title = title
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .textCase(nil)
    }
}

/// Hero-Karte: nächstes Konzert mit Countdown und Tageskennzahlen.
private struct HeroCard: View {
    let concert: Concert?
    let todayCount: Int
    let weekCount: Int
    let warningCount: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 14) {
                if let concert {
                    NavigationLink {
                        ConcertDetailView(concert: concert)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NÄCHSTES KONZERT")
                                .font(.caption2.weight(.bold))
                                .tracking(1.2)
                                .foregroundStyle(Theme.gold)
                            Text(concert.title)
                                .font(.system(.title2, design: .serif).weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                            HStack(spacing: 8) {
                                Text(concert.daysUntilLabel)
                                    .font(.subheadline.weight(.bold))
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Theme.gold, in: Capsule())
                                    .foregroundStyle(Color(light: 0x3A0C09, dark: 0x3A0C09))
                                Text("\(concert.startTime.map { $0.formatted(date: .omitted, time: .shortened) + " · " } ?? "")\(concert.venue), \(concert.city)")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Willkommen beim TKC Content Hub")
                        .font(.system(.title3, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                    Text("Sobald Konzerte synchronisiert sind, erscheint hier das nächste.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }

                HStack(spacing: 10) {
                    StatChip(value: todayCount, label: "Heute", symbol: "sun.max.fill")
                    StatChip(value: weekCount, label: "7 Tage", symbol: "calendar")
                    StatChip(value: warningCount, label: "Hinweise", symbol: "exclamationmark.triangle.fill")
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Theme.brand.opacity(0.30), radius: 12, y: 6)
    }
}

private struct StatChip: View {
    let value: Int
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.caption).foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)").font(.subheadline.weight(.bold)).foregroundStyle(.white)
                Text(label).font(.caption2).foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct Warning {
    let icon: String
    let color: Color
    let text: String
}

private struct ContentRow: View {
    let item: ContentItem
    var body: some View {
        HStack {
            Image(systemName: item.contentType.symbol).foregroundStyle(item.platform.color)
            VStack(alignment: .leading) {
                Text(item.title)
                if let time = item.publishTime {
                    Text(time.formatted(date: .omitted, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(item.status.displayName)
                .font(.caption2)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(item.status.color.opacity(0.15), in: Capsule())
                .foregroundStyle(item.status.color)
        }
    }
}

private struct StatusSummaryView: View {
    let items: [ContentItem]

    var body: some View {
        ForEach(ContentStatus.allCases) { status in
            let count = items.filter { $0.status == status }.count
            if count > 0 {
                LabeledContent(status.displayName, value: "\(count)")
            }
        }
    }
}
