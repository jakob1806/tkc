import Foundation
import CryptoKit
import SwiftData

/// Lädt https://www.toelzerknabenchor.de/konzerte, extrahiert strukturierte Konzertdaten,
/// normalisiert sie und führt ein Upsert gegen den lokalen SwiftData-Store durch.
///
/// Wichtig: Content-Daten (ContentItem, Assets, Tasks) werden bei erneuter Synchronisation
/// NIEMALS überschrieben oder gelöscht - nur die Konzert-Stammdaten werden aktualisiert,
/// und auch nur die Felder, die die Quelle tatsächlich liefert.
///
/// Die Seite ist eine SvelteKit-App, die den Konzertkalender serverseitig in die initiale
/// HTML-Antwort rendert (bestätigt per curl), daher genügt ein einfacher HTTP GET + HTML-Parsing
/// ohne JavaScript-Ausführung. Die Quelle liefert zuverlässig nur: Titel, Datum, Uhrzeit, Stadt,
/// Veranstaltungsort und (optional) Ticketlink. Felder wie Programm, Mitwirkende, Dirigent und
/// Beschreibung liefert die Quelle aktuell nicht strukturiert - diese bleiben nach dem Sync leer
/// und sind manuell im Konzert-Detail pflegbar (siehe `Concert.isManuallyEdited`).
actor ConcertSyncService {
    enum SyncError: LocalizedError {
        case invalidResponse
        case noEventsFound

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Die Konzertseite konnte nicht geladen werden (keine Verbindung oder Server-Fehler)."
            case .noEventsFound: return "Auf der Konzertseite wurden keine Konzerte gefunden - evtl. hat sich das Seitenlayout geändert."
            }
        }
    }

    private static let deletedIdsKey = "concertSync.deletedExternalIds"

    /// Vom Nutzer gelöschte Konzerte, die die Quelle weiterhin führt - werden beim Sync nicht neu angelegt.
    static func markDeleted(externalId: String) {
        var ids = Set(UserDefaults.standard.stringArray(forKey: deletedIdsKey) ?? [])
        ids.insert(externalId)
        UserDefaults.standard.set(Array(ids), forKey: deletedIdsKey)
    }

    private static var deletedIds: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: deletedIdsKey) ?? [])
    }

    static let sourceURL = URL(string: "https://www.toelzerknabenchor.de/konzerte")!

    private static let germanMonths: [String: Int] = [
        "Jan": 1, "Feb": 2, "Mär": 3, "Apr": 4, "Mai": 5, "Jun": 6,
        "Jul": 7, "Aug": 8, "Sep": 9, "Okt": 10, "Nov": 11, "Dez": 12,
    ]

    struct ParsedConcert {
        var weekday: String
        var day: Int
        var month: Int
        var time: String?
        var location: String?
        var ticketURL: String?
        var title: String
    }

    struct SyncResult {
        var inserted: Int
        var updated: Int
        var unchanged: Int
        var total: Int
    }

    /// Lädt die Konzertseite und liefert die geparsten Rohdaten (ohne Jahres-Auflösung).
    func fetchAndParse() async throws -> [ParsedConcert] {
        var request = URLRequest(url: Self.sourceURL)
        request.setValue("Mozilla/5.0 (compatible; TKC-ContentHub/1.0)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            throw SyncError.invalidResponse
        }
        let parsed = Self.parseEventCards(from: html)
        guard !parsed.isEmpty else { throw SyncError.noEventsFound }
        return parsed
    }

    /// Extrahiert alle `event-card`-Blöcke aus dem HTML und parst deren Felder.
    static func parseEventCards(from html: String) -> [ParsedConcert] {
        let cards = html.components(separatedBy: "\"event-card ").dropFirst()
        var results: [ParsedConcert] = []

        for rawCard in cards {
            // Ein Kartenblock endet spätestens beim nächsten Trenner-SVG.
            let card = String(rawCard.prefix(2000))

            guard let weekday = firstMatch(#"font-serif text-xl text-center\">([^<]+)<"#, in: card),
                  let dateLabel = firstMatch(#"font-serif text-2xl text-center\">([^<]+)<"#, in: card),
                  let title = firstMatch(#"font-serif font-bold[^\"]*\">([^<]+)<"#, in: card)
            else { continue }

            let dayMonth = dateLabel.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let day = Int(dayMonth.first ?? ""), dayMonth.count > 1,
                  let month = germanMonths[dayMonth[1]] else { continue }

            let time = firstMatch(#"mb-1\"><p>([0-9]{1,2}:[0-9]{2})</p>"#, in: card)
            let location = firstMatch(#"class=\"italic\">([^<]+)<"#, in: card)
            let ticketURL = firstMatch(#"<a href=\"([^\"]+)\" role=\"button\" class=\"btn btn-primary"#, in: card)

            results.append(ParsedConcert(
                weekday: weekday,
                day: day,
                month: month,
                time: time,
                location: location,
                ticketURL: ticketURL,
                title: title.replacingOccurrences(of: "&amp;", with: "&")
            ))
        }
        return results
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }

    /// Löst Tag/Monat-Paare (ohne Jahr) zu echten Daten auf. Die Liste ist chronologisch;
    /// ein Sprung von einem hohen Monat (z.B. Dez) zu einem niedrigen (z.B. Jan/Apr) bedeutet
    /// Jahreswechsel. Das Startjahr des ersten Eintrags wird so gewählt, dass das Datum am
    /// nächsten an "heute" liegt (die Quelle zeigt kürzlich vergangene und kommende Konzerte) -
    /// sonst wären Konzerte im Januar-Fenster nach Silvester ein Jahr zu spät.
    static func resolveYears(_ parsed: [ParsedConcert], referenceDate: Date, calendar: Calendar = .current) -> [(ParsedConcert, Date)] {
        guard let first = parsed.first else { return [] }
        let refYear = calendar.component(.year, from: referenceDate)
        let startYear = [refYear - 1, refYear, refYear + 1].min { lhs, rhs in
            distance(year: lhs, of: first, to: referenceDate, calendar: calendar)
                < distance(year: rhs, of: first, to: referenceDate, calendar: calendar)
        } ?? refYear

        var year = startYear
        var lastMonth = 0
        var out: [(ParsedConcert, Date)] = []
        for item in parsed {
            if item.month < lastMonth - 1 { year += 1 }
            lastMonth = item.month
            var components = DateComponents()
            components.year = year
            components.month = item.month
            components.day = item.day
            if let time = item.time {
                let parts = time.split(separator: ":")
                components.hour = Int(parts[0])
                components.minute = Int(parts[1])
            } else {
                components.hour = 0
                components.minute = 0
            }
            let date = calendar.date(from: components) ?? .now
            out.append((item, date))
        }
        return out
    }

    private static func distance(year: Int, of item: ParsedConcert, to reference: Date, calendar: Calendar) -> TimeInterval {
        var components = DateComponents()
        components.year = year
        components.month = item.month
        components.day = item.day
        guard let date = calendar.date(from: components) else { return .infinity }
        return abs(date.timeIntervalSince(reference))
    }

    /// Erzeugt eine stabile, deduplizierende ID aus Datum + Titel + Ort. Muss über App-Starts
    /// hinweg identisch bleiben (`hashValue` ist pro Prozess zufällig gesalzen und erzeugte bei
    /// jedem Neustart Duplikate), daher SHA-256.
    static func externalId(for item: ParsedConcert, date: Date) -> String {
        let dayKey = ISO8601DateFormatter().string(from: date).prefix(10)
        let raw = "\(dayKey)|\(item.title)|\(item.location ?? "")"
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.prefix(12).map { String(format: "%02x", $0) }.joined()
    }

    /// Führt Fetch, Parsing und Upsert in einem Rutsch durch.
    @MainActor
    static func syncNow(context: ModelContext, referenceDate: Date = .now) async throws -> SyncResult {
        let service = ConcertSyncService()
        let parsed = try await service.fetchAndParse()
        let calendar = Calendar.current
        let resolved = resolveYears(parsed, referenceDate: referenceDate, calendar: calendar)

        var inserted = 0
        var updated = 0
        var unchanged = 0

        let skipped = deletedIds
        for (item, date) in resolved {
            let extId = externalId(for: item, date: date)
            if skipped.contains(extId) { continue }
            let descriptor = FetchDescriptor<Concert>(predicate: #Predicate { $0.externalId == extId })
            var existing = try? context.fetch(descriptor).first
            if existing == nil {
                // Konzerte aus Versionen mit instabiler ID (Duplikat-Bug) über Titel + Datum
                // wiederfinden und auf die stabile ID umstellen statt sie doppelt anzulegen.
                let title = item.title
                let legacy = FetchDescriptor<Concert>(predicate: #Predicate { $0.title == title && $0.date == date })
                if let match = try? context.fetch(legacy).first {
                    match.externalId = extId
                    existing = match
                }
            }

            let (city, venue, address) = splitLocation(item.location)

            if let concert = existing {
                var changed = false
                if !concert.isManuallyEdited {
                    if concert.title != item.title { concert.title = item.title; changed = true }
                    if concert.date != date { concert.date = date; changed = true }
                    let start: Date? = item.time == nil ? nil : date
                    if concert.startTime != start { concert.startTime = start; changed = true }
                    if concert.venue != venue { concert.venue = venue; changed = true }
                    if concert.city != city { concert.city = city; changed = true }
                    if address != nil && concert.address != address { concert.address = address; changed = true }
                    if item.ticketURL != nil && concert.ticketURL != item.ticketURL { concert.ticketURL = item.ticketURL; changed = true }
                }
                concert.lastSyncedAt = .now
                if changed { updated += 1 } else { unchanged += 1 }
            } else {
                let concert = Concert(
                    externalId: extId,
                    title: item.title,
                    date: date,
                    startTime: item.time == nil ? nil : date,
                    venue: venue,
                    city: city,
                    address: address,
                    ticketURL: item.ticketURL,
                    sourceURL: sourceURL.absoluteString,
                    lastSyncedAt: .now
                )
                context.insert(concert)
                inserted += 1
            }
        }

        try context.save()
        return SyncResult(inserted: inserted, updated: updated, unchanged: unchanged, total: resolved.count)
    }

    /// "München: Isarphilharmonie, Hans-Preißinger-Straße 8, 81379 München, Deutschland"
    /// -> Stadt, Veranstaltungsort, Adresse
    private static func splitLocation(_ raw: String?) -> (city: String, venue: String, address: String?) {
        guard let raw, let colonRange = raw.range(of: ": ") else {
            return (raw ?? "Unbekannt", raw ?? "Ort folgt", nil)
        }
        let city = String(raw[raw.startIndex..<colonRange.lowerBound])
        let rest = String(raw[colonRange.upperBound...])
        let parts = rest.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let venue = parts.first ?? rest
        let address = parts.count > 1
            ? parts[1].replacingOccurrences(of: ", Deutschland", with: "")
            : nil
        return (city, venue, address)
    }

    private static let lastSyncKey = "concertSync.lastSuccessAt"

    /// Automatischer Abruf beim App-Start/Vordergrund: nur wenn der letzte erfolgreiche Sync
    /// länger als `minInterval` her ist. Fehler (z.B. offline) werden bewusst geschluckt -
    /// der manuelle Button meldet sie weiterhin.
    @MainActor
    static func syncIfStale(context: ModelContext, minInterval: TimeInterval = 6 * 3600) async {
        let defaults = UserDefaults.standard
        // Bei geänderter Sync-Logik (Version hochzählen) einmalig sofort neu abrufen.
        let versionKey = "concertSync.logicVersion"
        let currentVersion = 2
        let last = defaults.integer(forKey: versionKey) == currentVersion ? defaults.object(forKey: lastSyncKey) as? Date : nil
        if let last, Date.now.timeIntervalSince(last) < minInterval { return }
        if (try? await syncNow(context: context)) != nil {
            defaults.set(Date.now, forKey: lastSyncKey)
            defaults.set(currentVersion, forKey: versionKey)
        }
    }
}
