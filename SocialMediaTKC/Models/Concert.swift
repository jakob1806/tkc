import Foundation
import SwiftData

/// Ein Konzert des Tölzer Knabenchors, synchronisiert von toelzerknabenchor.de/konzerte.
/// Content-Daten (ContentItem) werden bei erneuter Synchronisation NIE überschrieben oder gelöscht.
@Model
final class Concert {
    @Attribute(.unique) var externalId: String
    var title: String
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var venue: String
    var city: String
    var address: String?
    var concertDescription: String?
    var program: String?
    var performers: String?
    var conductor: String?
    var ensemble: String?
    var ticketURL: String?
    var sourceURL: String?
    var lastSyncedAt: Date?

    /// Manuelle Überschreibungen durch den Nutzer werden beim Sync respektiert (kein Feld-Reset).
    var isManuallyEdited: Bool

    /// Manuell gepflegt (die Konzertseite liefert keine Verkaufszahlen über eine API):
    /// Grundlage für die Content-Timing-Korrelation (§9-Erweiterung).
    var ticketsSold: Int?
    var venueCapacity: Int?

    @Relationship(deleteRule: .nullify, inverse: \ContentItem.concert)
    var contentItems: [ContentItem] = []

    init(
        externalId: String,
        title: String,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        venue: String,
        city: String,
        address: String? = nil,
        concertDescription: String? = nil,
        program: String? = nil,
        performers: String? = nil,
        conductor: String? = nil,
        ensemble: String? = nil,
        ticketURL: String? = nil,
        sourceURL: String? = nil,
        lastSyncedAt: Date? = nil,
        isManuallyEdited: Bool = false
    ) {
        self.externalId = externalId
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.venue = venue
        self.city = city
        self.address = address
        self.concertDescription = concertDescription
        self.program = program
        self.performers = performers
        self.conductor = conductor
        self.ensemble = ensemble
        self.ticketURL = ticketURL
        self.sourceURL = sourceURL
        self.lastSyncedAt = lastSyncedAt
        self.isManuallyEdited = isManuallyEdited
    }

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0
    }

    var isPast: Bool { date < .now }

    var occupancyRate: Double? {
        guard let ticketsSold, let venueCapacity, venueCapacity > 0 else { return nil }
        return Double(ticketsSold) / Double(venueCapacity)
    }
}
