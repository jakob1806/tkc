import Foundation
import SwiftData

enum VoicePart: String, Codable, CaseIterable, Identifiable {
    case sopranoI, sopranoII, altoI, altoII, tenor, bass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sopranoI: return "Sopran I"
        case .sopranoII: return "Sopran II"
        case .altoI: return "Alt I"
        case .altoII: return "Alt II"
        case .tenor: return "Tenor"
        case .bass: return "Bass"
        }
    }
}

/// Chor & Besetzung: ein Sänger (Knabe oder Mann) mit Stimmgruppe.
@Model
final class Singer {
    var name: String
    var voicePartRaw: String
    var isActive: Bool
    var contact: String?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \CastAssignment.singer)
    var assignments: [CastAssignment] = []

    init(name: String, voicePart: VoicePart, isActive: Bool = true, contact: String? = nil, notes: String? = nil) {
        self.name = name
        self.voicePartRaw = voicePart.rawValue
        self.isActive = isActive
        self.contact = contact
        self.notes = notes
    }

    var voicePart: VoicePart {
        get { VoicePart(rawValue: voicePartRaw) ?? .sopranoI }
        set { voicePartRaw = newValue.rawValue }
    }
}

enum CastStatus: String, Codable, CaseIterable, Identifiable {
    case requested, confirmed, declined

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .requested: return "Angefragt"
        case .confirmed: return "Bestätigt"
        case .declined: return "Abgesagt"
        }
    }
}

/// Verknüpft einen Sänger mit einem Projekt (Besetzung/Verfügbarkeit für z.B. "Zauberflöte – Zürich").
@Model
final class CastAssignment {
    var statusRaw: String
    var role: String?

    var singer: Singer?
    var project: Project?

    init(status: CastStatus = .requested, role: String? = nil) {
        self.statusRaw = status.rawValue
        self.role = role
    }

    var status: CastStatus {
        get { CastStatus(rawValue: statusRaw) ?? .requested }
        set { statusRaw = newValue.rawValue }
    }
}
