import Foundation
import SwiftData

@Model
final class ContentItem {
    var title: String
    var date: Date
    var publishTime: Date?
    var platformRaw: String
    var contentTypeRaw: String
    var statusRaw: String
    var priorityRaw: Int
    var assignee: String?

    var caption: String?
    var storyText: String?
    var youtubeTitle: String?
    var youtubeDescription: String?
    var whatsappText: String?
    var facebookText: String?
    var callToAction: String?
    var hashtags: String?
    var notes: String?
    var links: String?
    var publishedURL: String?

    /// §20 "Ungeplant"-Bereich: Idee ohne festes Datum. `date` bleibt auf dem Erstellungsdatum
    /// als Platzhalter, wird aber in Kalender/Board/Timeline ausgeblendet, solange dieses Flag gesetzt ist.
    var isUnplanned: Bool

    var approvalStatusRaw: String
    var approvedBy: String?
    var approvedAt: Date?
    var approvalComment: String?

    /// Relative Bindung an ein Konzert (§ Ergänzung). Wenn gesetzt, verschiebt sich `date`/`publishTime`
    /// automatisch mit, sobald sich `concert.date` ändert (siehe ContentScheduler.resync).
    var relativeOffsetData: Data?

    var createdAt: Date
    var updatedAt: Date

    var concert: Concert?

    @Relationship(deleteRule: .cascade, inverse: \ContentTask.contentItem)
    var tasks: [ContentTask] = []

    @Relationship(deleteRule: .cascade, inverse: \Asset.contentItem)
    var assets: [Asset] = []

    init(
        title: String,
        date: Date,
        publishTime: Date? = nil,
        platform: Platform,
        contentType: ContentType,
        status: ContentStatus = .idea,
        priority: Priority = .medium,
        assignee: String? = nil,
        concert: Concert? = nil,
        relativeOffset: RelativeOffset? = nil,
        isUnplanned: Bool = false
    ) {
        self.title = title
        self.date = date
        self.publishTime = publishTime
        self.platformRaw = platform.rawValue
        self.contentTypeRaw = contentType.rawValue
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.assignee = assignee
        self.isUnplanned = isUnplanned
        self.approvalStatusRaw = ApprovalStatus.draft.rawValue
        self.createdAt = .now
        self.updatedAt = .now
        self.concert = concert
        self.relativeOffsetData = try? JSONEncoder().encode(relativeOffset)
    }

    var platform: Platform {
        get { Platform(rawValue: platformRaw) ?? .instagram }
        set { platformRaw = newValue.rawValue }
    }

    var contentType: ContentType {
        get { ContentType(rawValue: contentTypeRaw) ?? .other }
        set { contentTypeRaw = newValue.rawValue }
    }

    var status: ContentStatus {
        get { ContentStatus(rawValue: statusRaw) ?? .idea }
        set { statusRaw = newValue.rawValue }
    }

    var priority: Priority {
        get { Priority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    var approvalStatus: ApprovalStatus {
        get { ApprovalStatus(rawValue: approvalStatusRaw) ?? .draft }
        set { approvalStatusRaw = newValue.rawValue }
    }

    var relativeOffset: RelativeOffset? {
        get { relativeOffsetData.flatMap { try? JSONDecoder().decode(RelativeOffset.self, from: $0) } }
        set { relativeOffsetData = try? JSONEncoder().encode(newValue) }
    }

    var taskProgress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter(\.completed).count) / Double(tasks.count)
    }

    // MARK: - Intelligente Warnungen (§16)

    var isMissingCaption: Bool {
        (caption == nil || caption!.isEmpty) && (storyText == nil || storyText!.isEmpty)
    }

    var isMissingAsset: Bool { assets.isEmpty }

    var isMissingPublishTime: Bool { publishTime == nil }

    var isOverdue: Bool {
        guard let publishTime else { return false }
        return publishTime < .now && status != .published && status != .discarded
    }

    var isLongPendingApproval: Bool {
        approvalStatus == .requested && updatedAt.timeIntervalSinceNow < -3 * 24 * 3600
    }
}
