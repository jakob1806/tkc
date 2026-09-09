import Foundation
import SwiftData

/// §5 Synchronisation: neue Posts häufiger, alte Posts seltener. Die Schwellwerte sind über
/// `AppSettings` konfigurierbar (Standardwerte genau wie im Konzept vorgegeben).
enum SocialAnalyticsSyncScheduler {
    /// Wie lange her darf der letzte Snapshot höchstens sein, bevor ein Post erneut
    /// synchronisiert werden sollte - gestaffelt nach Alter des Posts.
    static func syncInterval(forPostAgeHours ageHours: Double) -> TimeInterval {
        let settings = AppSettings.shared
        switch ageHours {
        case ..<48: return settings.socialSyncIntervalUnder48h * 3600
        case 48..<(24 * 7): return settings.socialSyncInterval2to7Days * 3600
        case (24 * 7)..<(24 * 30): return settings.socialSyncInterval7to30Days * 3600
        default: return settings.socialSyncIntervalOver30Days * 3600
        }
    }

    static func isDue(post: SocialPost) -> Bool {
        guard let latest = post.latestSnapshot else { return true }
        let interval = syncInterval(forPostAgeHours: post.ageInHours)
        return Date.now.timeIntervalSince(latest.capturedAt) >= interval
    }

    /// Providerauswahl je Plattform (§2/§29 - Protocol-basierte Abstraktion, keine
    /// plattformspezifische Logik in den Views).
    private static func provider(for platform: SocialPlatform) -> SocialAnalyticsProvider {
        switch platform {
        case .instagram: return InstagramAnalyticsProvider()
        case .facebook: return FacebookAnalyticsProvider()
        case .tiktok: return TikTokAnalyticsProvider()
        case .youtube: return YouTubeAnalyticsProvider()
        }
    }

    struct SyncResult {
        var accountsSynced: Int = 0
        var postsUpdated: Int = 0
        var errors: [String] = []
    }

    /// Synchronisiert alle verbundenen Accounts. Da die vier Provider aktuell Stubs sind
    /// (kein Backend hinterlegt), schlägt jeder Call mit `.notConnected` fehl - das wird
    /// sauber als `lastSyncError` am Account gespeichert statt die App abstürzen zu lassen
    /// oder Werte zu erfinden (§30).
    @MainActor
    static func syncAll(context: ModelContext) async -> SyncResult {
        var result = SyncResult()
        let accounts = (try? context.fetch(FetchDescriptor<SocialAccount>())) ?? []

        for account in accounts where account.connected {
            let provider = provider(for: account.platform)
            do {
                let remoteAccount = try await provider.fetchAccount(externalAccountId: account.externalAccountId)
                account.username = remoteAccount.username
                account.displayName = remoteAccount.displayName
                account.followerCount = remoteAccount.followerCount
                account.lastSyncError = nil
                account.lastSyncedAt = .now
                result.accountsSynced += 1

                for post in account.posts where isDue(post: post) {
                    let snapshot = try await provider.fetchSnapshot(externalPostId: post.externalPostId)
                    let entry = SocialMetricSnapshot(
                        views: snapshot.views, likes: snapshot.likes, comments: snapshot.comments,
                        shares: snapshot.shares, saves: snapshot.saves, reach: snapshot.reach,
                        impressions: snapshot.impressions, watchTimeMinutes: snapshot.watchTimeMinutes,
                        averageWatchTimeSeconds: snapshot.averageWatchTimeSeconds
                    )
                    entry.post = post
                    context.insert(entry)
                    result.postsUpdated += 1
                }
            } catch {
                account.lastSyncError = (error as? SocialAnalyticsProviderError) != nil ? .platformUnreachable : .platformUnreachable
                result.errors.append("\(account.platform.displayName) (\(account.username)): \(error.localizedDescription)")
            }
        }

        try? context.save()
        return result
    }
}
