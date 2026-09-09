import Foundation

/// Reine Auswertungslogik über SocialPost/SocialMetricSnapshot - die Views bekommen nur
/// normalisierte Ergebnisse, keine API- oder Plattform-Details (§29).
enum SocialAnalyticsRepository {
    enum ValueMode { case absolute, growth }

    /// Summe einer Kennzahl über den aktuellsten Snapshot jedes Posts im Zeitraum (absolut)
    /// oder die Differenz zwischen erstem und letztem Snapshot im Zeitraum (Wachstum, §10).
    static func total(_ metric: SocialMetric, posts: [SocialPost], range: ClosedRange<Date>, mode: ValueMode) -> Int? {
        var sum = 0
        var anyValue = false
        for post in posts {
            let snapshotsInRange = post.sortedSnapshots.filter { range.contains($0.capturedAt) }
            guard !snapshotsInRange.isEmpty else { continue }
            switch mode {
            case .absolute:
                if let value = snapshotsInRange.last?.value(for: metric) {
                    sum += value; anyValue = true
                }
            case .growth:
                if let first = snapshotsInRange.first?.value(for: metric),
                   let last = snapshotsInRange.last?.value(for: metric) {
                    sum += max(0, last - first); anyValue = true
                }
            }
        }
        return anyValue ? sum : nil
    }

    /// Zeitreihe für eine Kennzahl/Plattform-Kombination - eine Linie im Hauptdiagramm (§8).
    struct SeriesPoint: Identifiable {
        let date: Date
        let value: Int
        var id: Date { date }
    }

    static func series(_ metric: SocialMetric, posts: [SocialPost], range: ClosedRange<Date>) -> [SeriesPoint] {
        let calendar = Calendar.current
        var byDay: [Date: Int] = [:]
        for post in posts {
            for snapshot in post.sortedSnapshots where range.contains(snapshot.capturedAt) {
                guard let value = snapshot.value(for: metric) else { continue }
                let day = calendar.startOfDay(for: snapshot.capturedAt)
                byDay[day] = max(byDay[day] ?? 0, value)
            }
        }
        return byDay.map { SeriesPoint(date: $0.key, value: $0.value) }.sorted { $0.date < $1.date }
    }

    /// §15 Plattform-Vergleich: Prozentanteile einer Kennzahl über die letzten N Tage.
    static func platformShare(_ metric: SocialMetric, posts: [SocialPost], range: ClosedRange<Date>) -> [(SocialPlatform, Double)] {
        let totals = SocialPlatform.allCases.map { platform -> (SocialPlatform, Int) in
            let platformPosts = posts.filter { $0.platform == platform }
            let value = total(metric, posts: platformPosts, range: range, mode: .absolute) ?? 0
            return (platform, value)
        }
        let grandTotal = totals.reduce(0) { $0 + $1.1 }
        guard grandTotal > 0 else { return totals.map { ($0.0, 0) } }
        return totals.map { ($0.0, Double($0.1) / Double(grandTotal) * 100) }
    }

    /// §25 Viral Detection: vergleicht das Wachstum eines Posts in den ersten Stunden mit dem
    /// historischen Durchschnitt anderer Posts derselben Plattform zum selben Zeitpunkt seit
    /// Veröffentlichung. Erfordert mindestens 5 Vergleichsposts, um Zufallstreffer bei kleiner
    /// Stichprobe zu vermeiden (§25 "keine willkürliche Definition von viral").
    static func isTrending(_ post: SocialPost, allPosts: [SocialPost], checkpointHours: Double = 24) -> Bool {
        guard let views = viewsAtHour(post, hours: checkpointHours) else { return false }
        let comparablePosts = allPosts.filter { $0.platform == post.platform && $0.persistentModelID != post.persistentModelID }
        let comparableViews = comparablePosts.compactMap { viewsAtHour($0, hours: checkpointHours) }
        guard comparableViews.count >= 5 else { return false }
        let average = Double(comparableViews.reduce(0, +)) / Double(comparableViews.count)
        guard average > 0 else { return false }
        return Double(views) >= average * 2
    }

    private static func viewsAtHour(_ post: SocialPost, hours: Double) -> Int? {
        let cutoff = post.publishedAt.addingTimeInterval(hours * 3600)
        return post.sortedSnapshots.last { $0.capturedAt <= cutoff }?.views
    }

    /// §14 Post-Vergleich, normalisiert nach Stunden seit Veröffentlichung statt Kalenderdatum.
    struct NormalizedPoint: Identifiable {
        let postTitle: String
        let hoursSincePublish: Double
        let value: Int
        var id: String { "\(postTitle)-\(hoursSincePublish)" }
    }

    static func normalizedSeries(_ metric: SocialMetric, posts: [SocialPost]) -> [NormalizedPoint] {
        posts.flatMap { post in
            post.sortedSnapshots.compactMap { snapshot -> NormalizedPoint? in
                guard let value = snapshot.value(for: metric) else { return nil }
                let hours = snapshot.capturedAt.timeIntervalSince(post.publishedAt) / 3600
                return NormalizedPoint(postTitle: post.caption ?? post.externalPostId, hoursSincePublish: hours, value: value)
            }
        }
    }
}
