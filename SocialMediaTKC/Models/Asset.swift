import Foundation
import SwiftData

@Model
final class Asset {
    var typeRaw: String
    var title: String
    var fileURL: String?
    var externalURL: String?
    var createdAt: Date

    /// Echte Foto-/Video-Importe aus der Mediathek (§1-Erweiterung, statt nur Link-Assets).
    /// `.externalStorage` lagert große Blobs effizient außerhalb der SQLite-Datei.
    @Attribute(.externalStorage) var mediaData: Data?
    var mediaFilenameExtension: String?

    var contentItem: ContentItem?

    init(type: AssetType, title: String, fileURL: String? = nil, externalURL: String? = nil, mediaData: Data? = nil, mediaFilenameExtension: String? = nil) {
        self.typeRaw = type.rawValue
        self.title = title
        self.fileURL = fileURL
        self.externalURL = externalURL
        self.mediaData = mediaData
        self.mediaFilenameExtension = mediaFilenameExtension
        self.createdAt = .now
    }

    var type: AssetType {
        get { AssetType(rawValue: typeRaw) ?? .document }
        set { typeRaw = newValue.rawValue }
    }

    var hasEmbeddedMedia: Bool { mediaData != nil }
}
