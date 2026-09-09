import Foundation

/// Meta Graph API für eine Facebook-Seite (bewusst getrennt von Instagram implementiert,
/// obwohl beide über dieselbe Graph API laufen - Post-Typen und Insights unterscheiden sich).
///
/// Reale Endpunkte, die das Backend ansteuern würde:
/// - Account: `GET /{page-id}?fields=name,username,fan_count,picture`
/// - Posts:   `GET /{page-id}/posts?fields=id,message,created_time,permalink_url,full_picture`
/// - Insights je Post: `GET /{post-id}/insights?metric=post_impressions,post_reactions_by_type_total,
///   post_video_views` (Reactions statt "Likes" - Facebook unterscheidet Reaction-Typen)
///
/// Benötigt serverseitig ein Page Access Token mit `pages_read_engagement`,
/// `read_insights`.
struct FacebookAnalyticsProvider: SocialAnalyticsProvider {
    let platform: SocialPlatform = .facebook

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
