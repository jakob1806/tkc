import Foundation
import SwiftData

enum ProjectKind: String, Codable, CaseIterable, Identifiable {
    case production, tour, standalone

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .production: return "Produktion"
        case .tour: return "Tournee"
        case .standalone: return "Einzelprojekt"
        }
    }

    var symbol: String {
        switch self {
        case .production: return "theatermasks"
        case .tour: return "bus"
        case .standalone: return "star"
        }
    }
}

/// Die verbindende Ebene der App (Konzeptsprung "Choir Operations System"): ein Projekt
/// bündelt Konzerte, ggf. eine Tournee, Besetzung und Content, statt getrennter Mini-Apps.
/// Beispiel: "Die Zauberflöte – Zürich" oder "Japan Tour 2027".
@Model
final class Project {
    var title: String
    var kindRaw: String
    var notes: String?
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Concert.project)
    var concerts: [Concert] = []

    @Relationship(deleteRule: .cascade, inverse: \Tour.project)
    var tour: Tour?

    @Relationship(deleteRule: .cascade, inverse: \CastAssignment.project)
    var castAssignments: [CastAssignment] = []

    init(title: String, kind: ProjectKind, notes: String? = nil) {
        self.title = title
        self.kindRaw = kind.rawValue
        self.notes = notes
        self.createdAt = .now
    }

    var kind: ProjectKind {
        get { ProjectKind(rawValue: kindRaw) ?? .standalone }
        set { kindRaw = newValue.rawValue }
    }

    var sortedConcerts: [Concert] { concerts.sorted { $0.date < $1.date } }

    var dateRangeLabel: String? {
        guard let first = sortedConcerts.first?.date else { return nil }
        guard let last = sortedConcerts.last?.date, last != first else {
            return first.formatted(date: .abbreviated, time: .omitted)
        }
        return "\(first.formatted(date: .abbreviated, time: .omitted)) – \(last.formatted(date: .abbreviated, time: .omitted))"
    }

    var contentItemCount: Int {
        concerts.reduce(0) { $0 + $1.contentItems.count }
    }
}
