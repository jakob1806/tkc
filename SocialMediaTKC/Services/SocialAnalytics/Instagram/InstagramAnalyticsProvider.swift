import Foundation

/// Instagram Graph API (über den verknüpften Facebook-Business-Account).
///
/// Reale Endpunkte, die das Backend ansteuern würde:
/// - Account: `GET /{ig-user-id}?fields=username,name,profile_picture_url,followers_count`
/// - Posts:   `GET /{ig-user-id}/media?fields=id,media_type,caption,timestamp,thumbnail_url,permalink`
/// - Insights je Post: `GET /{ig-media-id}/insights?metric=impressions,reach,likes,comments,saved,shares,plays`
///   (verfügbare Metriken hängen vom Media-Typ ab - Reels liefern z.B. `plays`, Feed-Posts nicht)
///
/// Benötigt serverseitig ein langlebiges Access Token eines Instagram-Business-/Creator-
/// Accounts plus die Berechtigungen `instagram_basic`, `instagram_manage_insights`.
struct InstagramAnalyticsProvider: SocialAnalyticsProvider {
    let platform: SocialPlatform = .instagram

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
