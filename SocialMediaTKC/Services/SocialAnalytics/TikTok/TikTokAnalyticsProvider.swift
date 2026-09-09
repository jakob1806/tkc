import Foundation

/// Offizielle TikTok API for Developers (Content Posting API / Display API), nur für
/// autorisierte, vom Chor selbst verwaltete Accounts nutzbar - kein Scraping.
///
/// Reale Endpunkte, die das Backend ansteuern würde:
/// - Account: `GET /v2/user/info/?fields=display_name,avatar_url,follower_count`
/// - Videos:  `GET /v2/video/list/?fields=id,create_time,cover_image_url,share_url,video_description`
/// - Kennzahlen je Video: `GET /v2/video/query/?fields=like_count,comment_count,share_count,view_count`
///
/// Benötigt serverseitig OAuth2 über den TikTok-Login-Kit-Flow und - je nach benötigtem
/// Scope - eine Freigabe der Beta/Produktions-App durch TikTok. Follower-Zuwachs pro
/// Video liefert die API nicht; nur der aktuelle Account-Follower-Stand ist verfügbar.
struct TikTokAnalyticsProvider: SocialAnalyticsProvider {
    let platform: SocialPlatform = .tiktok

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
