import Foundation
import SwiftData

/// Kommentar-Thread an einem Content-Item, z.B. für Hin-und-Her zwischen Redaktion und
/// Freigebenden (Erweiterung zu §14 Freigabeprozess).
@Model
final class Comment {
    var author: String
    var text: String
    var createdAt: Date

    var contentItem: ContentItem?

    init(author: String, text: String) {
        self.author = author
        self.text = text
        self.createdAt = .now
    }
}
