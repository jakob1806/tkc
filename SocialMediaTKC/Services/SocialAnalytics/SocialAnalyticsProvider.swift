import Foundation

/// Gemeinsames Protokoll für alle vier Plattform-Connectoren (§2, §29).
///
/// WICHTIG - Architekturprinzip: Die SwiftUI-App enthält keine API-Secrets. Ein
/// `SocialAnalyticsProvider` ruft in der Zielarchitektur nicht direkt Instagram/Facebook/
/// TikTok/YouTube auf, sondern ein eigenes Backend (z.B. Supabase Edge Functions), das die
/// OAuth-Tokens sicher verwahrt und die eigentlichen Plattform-Calls macht:
///
///   SwiftUI App → eigenes Backend → Social API Connector → Instagram/Facebook/TikTok/YouTube
///
/// Die vier konkreten Provider in diesem Ordner sind aktuell `Stub`-Implementierungen:
/// sie werfen `SocialAnalyticsProviderError.notConnected`, bis ein Backend-Endpunkt
/// hinterlegt ist (`AppSettings.shared.socialAnalyticsBackendURL`). Die Methoden-Signaturen
/// entsprechen exakt dem, was die jeweilige offizielle API liefert (siehe Kommentare in den
/// einzelnen Provider-Dateien) - ein Backend-Team muss nur noch `fetchAccount`/`fetchPosts`/
/// `fetchSnapshot` mit echten HTTP-Calls füllen, ohne dass sich UI oder Datenmodell ändern.
protocol SocialAnalyticsProvider {
    var platform: SocialPlatform { get }

    /// Lädt die Account-Stammdaten (Username, Follower, Profilbild) für ein bereits
    /// verbundenes Konto.
    func fetchAccount(externalAccountId: String) async throws -> RemoteAccountData

    /// Lädt neue/aktualisierte Posts seit einem Stichtag (nil = alle verfügbaren Posts,
    /// begrenzt durch das jeweilige API-Limit).
    func fetchPosts(externalAccountId: String, since: Date?) async throws -> [RemotePostData]

    /// Lädt einen aktuellen Kennzahlen-Snapshot für einen einzelnen Post.
    func fetchSnapshot(externalPostId: String) async throws -> RemoteSnapshotData
}

enum SocialAnalyticsProviderError: LocalizedError {
    case notConnected
    case backendNotConfigured

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Kein Backend verbunden. Social Analytics braucht einen Server, der die OAuth-Tokens hält (siehe SOCIAL_ANALYTICS_SETUP.md)."
        case .backendNotConfigured:
            return "Backend-URL fehlt (Einstellungen → Social Analytics)."
        }
    }
}

/// Normalisierte Rohdaten, wie sie ein Backend-Endpunkt zurückliefern würde - unabhängig
/// von den plattformspezifischen JSON-Formaten der einzelnen APIs.
struct RemoteAccountData {
    var username: String
    var displayName: String
    var profileImageURL: String?
    var followerCount: Int?
}

struct RemotePostData {
    var externalPostId: String
    var postType: SocialPostType
    var caption: String?
    var publishedAt: Date
    var thumbnailURL: String?
    var externalURL: String?
    var snapshot: RemoteSnapshotData
}

struct RemoteSnapshotData {
    var views: Int?
    var likes: Int?
    var comments: Int?
    var shares: Int?
    var saves: Int?
    var reach: Int?
    var impressions: Int?
    var watchTimeMinutes: Double?
    var averageWatchTimeSeconds: Double?
}
