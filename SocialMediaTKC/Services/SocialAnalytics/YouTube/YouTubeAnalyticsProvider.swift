import Foundation

/// Kombination aus YouTube Data API (Stammdaten/Video-Liste) und YouTube Analytics API
/// (Watch Time, Subscribers gained - die Data API allein liefert das nicht).
///
/// Reale Endpunkte, die das Backend ansteuern würde:
/// - Account: `GET youtube/v3/channels?part=snippet,statistics&mine=true`
/// - Videos:  `GET youtube/v3/search?part=snippet&forMine=true&type=video`
///   + `GET youtube/v3/videos?part=snippet,statistics,contentDetails&id=...`
///   (liefert views/likes/comments; `contentDetails.duration` unterscheidet Video vs. Short)
/// - Watch Time / Subscribers gained: `POST youtubeAnalytics/v2/reports` mit
///   `metrics=estimatedMinutesWatched,averageViewDuration,subscribersGained` und
///   `filters=video==<videoId>`
///
/// Benötigt serverseitig OAuth2 mit den Scopes `youtube.readonly` und
/// `yt-analytics.readonly` für einen Google-Account mit Kanalzugriff.
struct YouTubeAnalyticsProvider: SocialAnalyticsProvider {
    let platform: SocialPlatform = .youtube

    func fetchAccount(externalAccountId: String) async throws -> RemoteAccountData {
        throw SocialAnalyticsProviderError.notConnected
    }

    func fetchPosts(externalAccountId: String, since: Date?) async throws -> [RemotePostData] {
        throw SocialAnalyticsProviderError.notConnected
    }

    func fetchSnapshot(externalPostId: String) async throws -> RemoteSnapshotData {
        throw SocialAnalyticsProviderError.notConnected
    }
}
