import Foundation
import SwiftData

/// Erzeugt Content-Vorschläge für ein Konzert aus einem Template (§5, §11) und hält
/// relativ gebundene ContentItems synchron, wenn sich ein Konzerttermin verschiebt (§ Ergänzung).
enum ContentScheduler {
    /// Wendet ein Template auf ein Konzert an: legt für jede Template-Zeile ein neues
    /// ContentItem an, relativ an das Konzert gebunden. Bestehende Items werden nie gelöscht.
    static func applyTemplate(_ template: ContentTemplate, to concert: Concert, context: ModelContext) {
        for item in template.items.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let resolvedDate = item.offset.resolvedDate(relativeTo: concert.date)
            let contentItem = ContentItem(
                title: "\(item.title) – \(concert.title)",
                date: resolvedDate,
                publishTime: resolvedDate,
                platform: item.platform,
                contentType: item.contentType,
                status: .idea,
                concert: concert,
                relativeOffset: item.offset
            )
            context.insert(contentItem)
        }
    }

    /// Verschiebt alle relativ gebundenen ContentItems eines Konzerts neu, nachdem sich
    /// `concert.date` geändert hat. Bereits individuell überarbeitete Inhalte (Caption etc.)
    /// bleiben erhalten - nur Datum/Uhrzeit werden nachgezogen.
    static func resyncRelativeContent(for concert: Concert) {
        for item in concert.contentItems {
            guard let offset = item.relativeOffset else { continue }
            let newDate = offset.resolvedDate(relativeTo: concert.date)
            item.date = newDate
            item.publishTime = newDate
            item.updatedAt = .now
        }
    }

    // MARK: - Intelligente Warnungen (§16)

    static func concertsWithoutContentSoon(concerts: [Concert], within days: Int = 7) -> [Concert] {
        concerts.filter { $0.daysUntil >= 0 && $0.daysUntil <= days && $0.contentItems.isEmpty }
    }

    static func concertsTomorrowWithoutStory(concerts: [Concert]) -> [Concert] {
        concerts.filter { concert in
            concert.daysUntil == 1 && !concert.contentItems.contains { $0.contentType == .story }
        }
    }

    static func itemsTooClose(items: [ContentItem], minimumGapMinutes: Int = 30) -> [(ContentItem, ContentItem)] {
        // Nur kommende, noch nicht veröffentlichte Items pro Plattform vergleichen - zwei
        // Posts auf verschiedenen Kanälen zur selben Zeit sind kein Konflikt.
        var pairs: [(ContentItem, ContentItem)] = []
        let upcoming = items.filter { $0.status != .published && $0.status != .discarded && ($0.publishTime ?? .distantPast) > .now }
        for (_, group) in Dictionary(grouping: upcoming, by: \.platform) {
            let sorted = group.compactMap { item -> (ContentItem, Date)? in
                guard let t = item.publishTime else { return nil }
                return (item, t)
            }.sorted { $0.1 < $1.1 }
            for i in sorted.indices.dropFirst() {
                let gap = sorted[i].1.timeIntervalSince(sorted[i - 1].1)
                if gap < Double(minimumGapMinutes * 60) {
                    pairs.append((sorted[i - 1].0, sorted[i].0))
                }
            }
        }
        return pairs
    }
}
