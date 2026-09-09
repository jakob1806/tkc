import Foundation
import SwiftData

/// Ein wiederverwendbares Template (§11), bestehend aus mehreren Vorschlagszeilen,
/// die relativ zu einem Konzerttermin geplant werden.
@Model
final class ContentTemplate {
    var title: String
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ContentTemplateItem.template)
    var items: [ContentTemplateItem] = []

    init(title: String, isBuiltIn: Bool = false) {
        self.title = title
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }
}

@Model
final class ContentTemplateItem {
    var title: String
    var offsetData: Data
    var platformRaw: String
    var contentTypeRaw: String
    var sortOrder: Int

    var template: ContentTemplate?

    init(title: String, offset: RelativeOffset, platform: Platform, contentType: ContentType, sortOrder: Int) {
        self.title = title
        self.offsetData = (try? JSONEncoder().encode(offset)) ?? Data()
        self.platformRaw = platform.rawValue
        self.contentTypeRaw = contentType.rawValue
        self.sortOrder = sortOrder
    }

    var offset: RelativeOffset {
        (try? JSONDecoder().decode(RelativeOffset.self, from: offsetData)) ?? .announcement14
    }

    var platform: Platform { Platform(rawValue: platformRaw) ?? .instagram }
    var contentType: ContentType { ContentType(rawValue: contentTypeRaw) ?? .other }
}

extension ContentTemplate {
    /// Vordefinierte Standard-Templates (§11 + automatische Vorschläge §5).
    static func seedBuiltInTemplates(in context: ModelContext) {
        let descriptor = FetchDescriptor<ContentTemplate>(predicate: #Predicate { $0.isBuiltIn })
        if let existing = try? context.fetch(descriptor), !existing.isEmpty { return }

        func make(_ title: String, _ rows: [(String, RelativeOffset, Platform, ContentType)]) {
            let template = ContentTemplate(title: title, isBuiltIn: true)
            context.insert(template)
            for (index, row) in rows.enumerated() {
                let item = ContentTemplateItem(title: row.0, offset: row.1, platform: row.2, contentType: row.3, sortOrder: index)
                item.template = template
                context.insert(item)
            }
        }

        make("Konzert Standard (empfohlen)", [
            ("Save the Date", .saveTheDate21, .instagram, .feedPost),
            ("Konzertankündigung", .announcement14, .instagram, .feedPost),
            ("Reel / musikalischer Ausschnitt", .reel7, .instagramReel, .reel),
            ("Ticket Reminder", .ticketReminder3, .instagramStory, .story),
            ("Tomorrow Story", .tomorrowStory1, .instagramStory, .story),
            ("Tonight Story", .tonightMorning, .instagramStory, .story),
            ("Behind the Scenes", .behindTheScenes, .instagramStory, .story),
            ("Konzert Story", .concertEvening, .instagramStory, .story),
            ("Thank You / Rückblick", .thankYou1, .instagram, .feedPost),
            ("Reel / Konzertmitschnitt", .recap5, .instagramReel, .reel),
        ])

        make("Opernproduktion", [
            ("Announcement", .announcement14, .instagram, .feedPost),
            ("Rehearsal", .reel7, .instagramStory, .story),
            ("Premiere Reminder", .ticketReminder3, .instagramStory, .story),
            ("Premiere", .concertEvening, .instagramStory, .story),
            ("Behind the Scenes", .behindTheScenes, .instagramReel, .reel),
            ("Review", .thankYou1, .instagram, .feedPost),
        ])

        make("Tournee", [
            ("Tour Announcement", .announcement14, .instagram, .feedPost),
            ("Travel", .tomorrowStory1, .instagramStory, .story),
            ("Arrival", .tonightMorning, .instagramStory, .story),
            ("Venue", .behindTheScenes, .instagramStory, .story),
            ("Concert", .concertEvening, .instagramStory, .story),
            ("City Impression", .thankYou1, .instagramReel, .reel),
            ("Recap", .recap5, .instagram, .feedPost),
        ])
    }
}
