import Foundation
import SwiftData

enum LibraryCategory: String, Codable, CaseIterable, Identifiable {
    case hashtagGroup, link, ticketLink, standardText, credit, venue, partner, orchestra, photographer, videoCredit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hashtagGroup: return "Hashtag-Gruppe"
        case .link: return "Link"
        case .ticketLink: return "Ticketlink"
        case .standardText: return "Standardtext"
        case .credit: return "Credit / Künstlername"
        case .venue: return "Veranstaltungsort"
        case .partner: return "Partner"
        case .orchestra: return "Orchester / Ensemble"
        case .photographer: return "Fotograf"
        case .videoCredit: return "Video Credit"
        }
    }

    var symbol: String {
        switch self {
        case .hashtagGroup: return "number"
        case .link, .ticketLink: return "link"
        case .standardText: return "text.quote"
        case .credit: return "person.text.rectangle"
        case .venue: return "building.columns"
        case .partner: return "handshake"
        case .orchestra: return "pianokeys"
        case .photographer: return "camera"
        case .videoCredit: return "video"
        }
    }
}

/// §21 Content Library: zentral gespeicherte, wiederkehrende Angaben.
@Model
final class LibraryItem {
    var categoryRaw: String
    var title: String
    var value: String
    var createdAt: Date

    init(category: LibraryCategory, title: String, value: String) {
        self.categoryRaw = category.rawValue
        self.title = title
        self.value = value
        self.createdAt = .now
    }

    var category: LibraryCategory {
        get { LibraryCategory(rawValue: categoryRaw) ?? .standardText }
        set { categoryRaw = newValue.rawValue }
    }
}
