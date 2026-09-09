import Foundation
import SwiftData

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case contract, rider, travel, press, invoice, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .contract: return "Vertrag"
        case .rider: return "Bühnenplan/Rider"
        case .travel: return "Reiseunterlagen"
        case .press: return "Presseunterlagen"
        case .invoice: return "Rechnung"
        case .other: return "Sonstiges"
        }
    }

    var symbol: String {
        switch self {
        case .contract: return "doc.text"
        case .rider: return "theatermasks"
        case .travel: return "airplane"
        case .press: return "newspaper"
        case .invoice: return "eurosign.circle"
        case .other: return "doc"
        }
    }
}

/// Dokumenten-Hub: Verträge, Rider, Reiseunterlagen, Presse, Rechnungen - je Projekt/Konzert
/// zuordenbar statt verstreut in Mail/Dateien-App.
@Model
final class Document {
    var title: String
    var categoryRaw: String
    var createdAt: Date

    @Attribute(.externalStorage) var fileData: Data?
    var fileExtension: String?
    var externalURL: String?

    var project: Project?
    var concert: Concert?

    init(title: String, category: DocumentCategory, fileData: Data? = nil, fileExtension: String? = nil, externalURL: String? = nil) {
        self.title = title
        self.categoryRaw = category.rawValue
        self.fileData = fileData
        self.fileExtension = fileExtension
        self.externalURL = externalURL
        self.createdAt = .now
    }

    var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
