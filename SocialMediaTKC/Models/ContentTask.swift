import Foundation
import SwiftData

/// Named `ContentTask` (not `Task`) to avoid clashing with Swift Concurrency's `Task`.
@Model
final class ContentTask {
    var title: String
    var completed: Bool
    var createdAt: Date

    var contentItem: ContentItem?

    init(title: String, completed: Bool = false) {
        self.title = title
        self.completed = completed
        self.createdAt = .now
    }
}
