import Foundation
import SwiftData

/// §28-Ausbaustufe: Team-Synchronisation über Supabase.
///
/// Bewusst ohne das supabase-swift SPM-Paket implementiert, sondern direkt gegen die
/// PostgREST-Schnittstelle, die jedes Supabase-Projekt automatisch bereitstellt
/// (https://<project>.supabase.co/rest/v1/<table>). Das hält die Abhängigkeit minimal und
/// funktioniert mit jedem Supabase-Projekt, das die Tabellen aus SUPABASE_SETUP.md anlegt.
///
/// Architektur: lokal bleibt SwiftData die "Source of Truth" fürs Offline-Arbeiten; dieser
/// Service pusht Konzerte und Content-Einträge als Upsert nach Supabase (Prefer:
/// resolution=merge-duplicates), keyed über `external_id` / eine deterministische UUID.
/// Ein echter bidirektionaler Sync (Pull + Konflikterkennung + Realtime-Subscriptions) ist
/// der nächste Schritt, sobald ein Team das im Alltag nutzt - siehe SUPABASE_SETUP.md.
enum SupabaseSyncService {
    enum SyncError: LocalizedError {
        case missingConfiguration
        case invalidResponse(Int)

        var errorDescription: String? {
            switch self {
            case .missingConfiguration: return "Supabase-URL oder Anon Key fehlt (Einstellungen → Team-Sync)."
            case .invalidResponse(let code): return "Supabase antwortete mit Statuscode \(code)."
            }
        }
    }

    struct SyncResult {
        var concertsPushed: Int
        var contentItemsPushed: Int
    }

    private struct ConcertDTO: Encodable {
        let external_id: String
        let title: String
        let date: Date
        let venue: String
        let city: String
        let address: String?
        let ticket_url: String?
        let source_url: String?
        let tickets_sold: Int?
        let venue_capacity: Int?
    }

    private struct ContentItemDTO: Encodable {
        let id: String
        let title: String
        let date: Date
        let publish_time: Date?
        let platform: String
        let content_type: String
        let status: String
        let concert_external_id: String?
        let assignee: String?
        let caption: String?
        let updated_at: Date
    }

    private static func stableSyncId(for item: ContentItem) -> String {
        if let id = item.syncId { return id }
        let id = UUID().uuidString
        item.syncId = id
        return id
    }

    @MainActor
    static func syncAll(context: ModelContext) async throws -> SyncResult {
        let settings = AppSettings.shared
        guard !settings.supabaseURL.isEmpty, !settings.supabaseAnonKey.isEmpty,
              let baseURL = URL(string: settings.supabaseURL) else {
            throw SyncError.missingConfiguration
        }

        let concerts = try context.fetch(FetchDescriptor<Concert>())
        let contentItems = try context.fetch(FetchDescriptor<ContentItem>())

        let concertDTOs = concerts.map { concert in
            ConcertDTO(
                external_id: concert.externalId,
                title: concert.title,
                date: concert.date,
                venue: concert.venue,
                city: concert.city,
                address: concert.address,
                ticket_url: concert.ticketURL,
                source_url: concert.sourceURL,
                tickets_sold: concert.ticketsSold,
                venue_capacity: concert.venueCapacity
            )
        }
        try await upsert(concertDTOs, table: "concerts", baseURL: baseURL, anonKey: settings.supabaseAnonKey, conflictColumn: "external_id")

        let contentDTOs = contentItems.map { item in
            ContentItemDTO(
                id: stableSyncId(for: item),
                title: item.title,
                date: item.date,
                publish_time: item.publishTime,
                platform: item.platform.rawValue,
                content_type: item.contentType.rawValue,
                status: item.status.rawValue,
                concert_external_id: item.concert?.externalId,
                assignee: item.assignee,
                caption: item.caption,
                updated_at: item.updatedAt
            )
        }
        try await upsert(contentDTOs, table: "content_items", baseURL: baseURL, anonKey: settings.supabaseAnonKey, conflictColumn: "id")

        return SyncResult(concertsPushed: concertDTOs.count, contentItemsPushed: contentDTOs.count)
    }

    private static func upsert<T: Encodable>(_ rows: [T], table: String, baseURL: URL, anonKey: String, conflictColumn: String) async throws {
        guard !rows.isEmpty else { return }

        var url = baseURL.appendingPathComponent("rest/v1/\(table)")
        url = url.appending(queryItems: [URLQueryItem(name: "on_conflict", value: conflictColumn)])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(rows)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SyncError.invalidResponse(code)
        }
    }
}
