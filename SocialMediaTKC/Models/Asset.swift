import Foundation
import SwiftData

@Model
final class Asset {
    var typeRaw: String
    var title: String
    var fileURL: String?
    var externalURL: String?
    var createdAt: Date

    var contentItem: ContentItem?

    init(type: AssetType, title: String, fileURL: String? = nil, externalURL: String? = nil) {
        self.typeRaw = type.rawValue
        self.title = title
        self.fileURL = fileURL
        self.externalURL = externalURL
        self.createdAt = .now
    }

    var type: AssetType {
        get { AssetType(rawValue: typeRaw) ?? .document }
        set { typeRaw = newValue.rawValue }
    }
}
