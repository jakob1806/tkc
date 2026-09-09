import Foundation
import SwiftData

/// Chor Assistant (§KI-Konzept): natürlichsprachliche Abfrageschicht über die App-Daten.
/// Baut aus SwiftData einen kompakten Kontext-Snapshot (Konzerte, Projekte, Touren, Content,
/// Chor) und schickt ihn zusammen mit der Nutzerfrage an die Gemini `generateContent`-API.
///
/// Bewusst zustandslos zwischen Anfragen (kein Function-Calling, keine Schreibzugriffe) -
/// die KI beschreibt und schlägt vor, ändert aber nie direkt Daten. Das entspricht dem
/// Konzept-Grundsatz "externe Vorschläge werden erst nach Bestätigung übernommen".
enum GeminiAssistantService {
    enum AssistantError: LocalizedError {
        case missingAPIKey
        case invalidResponse(Int, String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "Kein Gemini API-Key hinterlegt (Einstellungen → Chor Assistant)."
            case .invalidResponse(let code, let body): return "Gemini antwortete mit Statuscode \(code): \(body.prefix(200))"
            case .emptyResponse: return "Gemini hat keine Antwort geliefert."
            }
        }
    }

    struct ChatMessage: Identifiable, Codable {
        var id = UUID()
        var role: Role
        var text: String

        enum Role: String, Codable { case user, model }
    }

    @MainActor
    static func ask(_ question: String, history: [ChatMessage], context: ModelContext) async throws -> String {
        let apiKey = AppSettings.shared.geminiAPIKey
        guard !apiKey.isEmpty else { throw AssistantError.missingAPIKey }

        let systemContext = try buildContextSnapshot(context: context)

        var url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")!
        url = url.appending(queryItems: [URLQueryItem(name: "key", value: apiKey)])

        var contents: [[String: Any]] = []
        for message in history {
            contents.append(["role": message.role.rawValue, "parts": [["text": message.text]]])
        }
        contents.append(["role": "user", "parts": [["text": question]]])

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt(with: systemContext)]]
            ],
            "contents": contents,
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw AssistantError.invalidResponse(code, String(data: data, encoding: .utf8) ?? "")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let firstCandidate = candidates.first,
            let contentDict = firstCandidate["content"] as? [String: Any],
            let parts = contentDict["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw AssistantError.emptyResponse
        }
        return text
    }

    private static func systemPrompt(with contextSnapshot: String) -> String {
        """
        Du bist der "Chor Assistant" des Tölzer Knabenchors, eingebettet in dessen internes \
        Choir-Operations-System (Konzerte, Content, Touren, Besetzung). Du beantwortest Fragen \
        der Redaktion/Tourleitung auf Deutsch, kurz und konkret, ausschließlich auf Basis der \
        unten stehenden Daten. Wenn eine Information fehlt, sag das explizit statt zu spekulieren. \
        Du kannst keine Daten in der App ändern - formuliere Vorschläge, die die Person selbst \
        in der App umsetzen muss.

        AKTUELLE DATEN:
        \(contextSnapshot)
        """
    }

    /// Kompakter Textschnappschuss der relevanten Daten - bewusst knapp gehalten, damit er
    /// in jedes Kontextfenster passt, auch bei größerem Datenbestand.
    private static func buildContextSnapshot(context: ModelContext) throws -> String {
        let concerts = try context.fetch(FetchDescriptor<Concert>(sortBy: [SortDescriptor(\.date)]))
        let projects = try context.fetch(FetchDescriptor<Project>())
        let contentItems = try context.fetch(FetchDescriptor<ContentItem>())
        let singers = try context.fetch(FetchDescriptor<Singer>())

        var lines: [String] = []

        lines.append("Konzerte (\(concerts.count)):")
        for concert in concerts.prefix(60) {
            let contentCount = concert.contentItems.count
            lines.append("- \(concert.date.formatted(date: .abbreviated, time: .omitted)) \(concert.title), \(concert.venue) \(concert.city), Content: \(contentCount), Projekt: \(concert.project?.title ?? "keins")")
        }

        lines.append("\nProjekte (\(projects.count)):")
        for project in projects {
            let confirmed = project.castAssignments.filter { $0.status == .confirmed }.count
            let requested = project.castAssignments.filter { $0.status == .requested }.count
            lines.append("- \(project.title) (\(project.kind.displayName)): \(project.concerts.count) Konzerte, Besetzung \(confirmed) bestätigt/\(requested) offen, Tour: \(project.tour != nil ? "\(project.tour!.days.count) Tage" : "keine")")
        }

        let openApprovals = contentItems.filter { $0.approvalStatus == .requested }.count
        let missingCaption = contentItems.filter(\.isMissingCaption).count
        let overdue = contentItems.filter(\.isOverdue).count
        lines.append("\nContent gesamt: \(contentItems.count), davon \(openApprovals) warten auf Freigabe, \(missingCaption) ohne Caption, \(overdue) überfällig.")

        lines.append("\nChor: \(singers.count) Sänger (\(singers.filter { !$0.isActive }.count) inaktiv).")
        for part in VoicePart.allCases {
            let count = singers.filter { $0.voicePart == part && $0.isActive }.count
            if count > 0 { lines.append("- \(part.displayName): \(count)") }
        }

        // §21 Social AI Analyst: Zugriff auf Social-Analytics-Daten, ausschließlich auf Basis
        // gespeicherter Snapshots - der Assistent soll nie Kennzahlen erfinden.
        let socialPosts = try context.fetch(FetchDescriptor<SocialPost>())
        let last30Days = Calendar.current.date(byAdding: .day, value: -30, to: .now)! ... Date.now
        lines.append("\nSocial Media (\(socialPosts.count) Posts insgesamt):")
        for platform in SocialPlatform.allCases {
            let platformPosts = socialPosts.filter { $0.platform == platform }
            guard !platformPosts.isEmpty else { continue }
            let views = SocialAnalyticsRepository.total(.views, posts: platformPosts, range: last30Days, mode: .absolute)
            let likes = SocialAnalyticsRepository.total(.likes, posts: platformPosts, range: last30Days, mode: .absolute)
            lines.append("- \(platform.displayName): \(platformPosts.count) Posts, letzte 30 Tage \(views.map(String.init) ?? "keine Daten") Views, \(likes.map(String.init) ?? "keine Daten") Likes")
        }
        let topPosts = socialPosts.sorted { ($0.latestSnapshot?.views ?? 0) > ($1.latestSnapshot?.views ?? 0) }.prefix(10)
        if !topPosts.isEmpty {
            lines.append("Top-Posts nach Views:")
            for post in topPosts {
                lines.append("- \(post.platform.displayName) \(post.postType.displayName) \"\(post.caption ?? post.externalPostId)\" (\(post.publishedAt.formatted(date: .abbreviated, time: .omitted))): \(post.latestSnapshot?.views.map(String.init) ?? "—") Views, \(post.latestSnapshot?.likes.map(String.init) ?? "—") Likes, \(post.latestSnapshot?.comments.map(String.init) ?? "—") Kommentare, \(post.latestSnapshot?.shares.map(String.init) ?? "—") Shares")
            }
        }

        return lines.joined(separator: "\n")
    }
}
