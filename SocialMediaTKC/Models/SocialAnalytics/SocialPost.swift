import Foundation
import SwiftData

/// Ein einzelner veröffentlichter Beitrag auf einer der vier Plattformen (§3, §16, §17).
/// Kann optional mit ContentItem (Contentplan), Concert und Project verknüpft werden.
@Model
final class SocialPost {
    var externalPostId: String
    var postTypeRaw: String
    var caption: String?
    var publishedAt: Date
    var thumbnailURL: String?
    var externalURL: String?

    var account: SocialAccount?
    var linkedContentItem: ContentItem?
    var linkedConcert: Concert?
    var linkedProject: Project?

    @Relationship(deleteRule: .cascade, inverse: \SocialMetricSnapshot.post)
    var snapshots: [SocialMetricSnapshot] = []

    init(
        externalPostId: String,
        postType: SocialPostType,
        caption: String? = nil,
        publishedAt: Date,
        thumbnailURL: String? = nil,
        externalURL: String? = nil
    ) {
        self.externalPostId = externalPostId
        self.postTypeRaw = postType.rawValue
        self.caption = caption
        self.publishedAt = publishedAt
        self.thumbnailURL = thumbnailURL
        self.externalURL = externalURL
    }

    var postType: SocialPostType {
        get { SocialPostType(rawValue: postTypeRaw) ?? .feedPost }
        set { postTypeRaw = newValue.rawValue }
    }

    var platform: SocialPlatform { account?.platform ?? .instagram }

    /// Neuester Snapshot - der "aktuelle Gesamtstand" (§10 Absolute Werte).
    var latestSnapshot: SocialMetricSnapshot? {
        snapshots.max { $0.capturedAt < $1.capturedAt }
    }

    var sortedSnapshots: [SocialMetricSnapshot] { snapshots.sorted { $0.capturedAt < $1.capturedAt } }

    /// §23 Engagement Rate by Views: (likes + comments + shares) / views × 100.
    /// Liefert nil, wenn Views unbekannt sind - nie künstlich 0 zeigen.
    var engagementRate: Double? {
        guard let latest = latestSnapshot, let views = latest.views, views > 0 else { return nil }
        let engagement = (latest.likes ?? 0) + (latest.comments ?? 0) + (latest.shares ?? 0)
        return Double(engagement) / Double(views) * 100
    }

    /// Alter des Posts seit Veröffentlichung - Grundlage für die Sync-Kadenz (§5).
    var ageInHours: Double { Date.now.timeIntervalSince(publishedAt) / 3600 }
}
