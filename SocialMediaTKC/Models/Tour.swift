import Foundation
import SwiftData

/// Eine Tournee gehört zu einem Projekt und besteht aus Reisetagen mit Tagesplänen
/// (Konzept: "Japan Tour 2027" mit 12 Konzerten, 14 Reisetagen).
@Model
final class Tour {
    var title: String
    var notes: String?

    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \TourDay.tour)
    var days: [TourDay] = []

    init(title: String, notes: String? = nil) {
        self.title = title
        self.notes = notes
    }

    var sortedDays: [TourDay] { days.sorted { $0.date < $1.date } }
}

/// Ein Reisetag mit Ort, Unterkunft und Tagesplan (Daily Schedule).
@Model
final class TourDay {
    var date: Date
    var cityOrLocation: String
    var hotelName: String?
    var hotelAddress: String?
    var notes: String?

    var tour: Tour?

    @Relationship(deleteRule: .cascade, inverse: \TourEvent.tourDay)
    var events: [TourEvent] = []

    init(date: Date, cityOrLocation: String, hotelName: String? = nil, hotelAddress: String? = nil, notes: String? = nil) {
        self.date = date
        self.cityOrLocation = cityOrLocation
        self.hotelName = hotelName
        self.hotelAddress = hotelAddress
        self.notes = notes
    }

    var sortedEvents: [TourEvent] { events.sorted { $0.time < $1.time } }
}

enum TourEventType: String, Codable, CaseIterable, Identifiable {
    case meal, meetingPoint, transfer, rehearsal, concert, freeTime, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meal: return "Essen"
        case .meetingPoint: return "Treffpunkt"
        case .transfer: return "Transfer"
        case .rehearsal: return "Probe"
        case .concert: return "Konzert"
        case .freeTime: return "Freizeit"
        case .other: return "Sonstiges"
        }
    }

    var symbol: String {
        switch self {
        case .meal: return "fork.knife"
        case .meetingPoint: return "person.2.wave.2"
        case .transfer: return "bus"
        case .rehearsal: return "figure.stand.line.dotted.figure.stand"
        case .concert: return "music.mic"
        case .freeTime: return "leaf"
        case .other: return "ellipsis.circle"
        }
    }
}

/// Ein einzelner Punkt im Tagesplan, z.B. "09:30 Bus zum Bahnhof".
@Model
final class TourEvent {
    var time: Date
    var title: String
    var typeRaw: String
    var location: String?
    var notes: String?
    var busOrSeatInfo: String?

    var tourDay: TourDay?

    init(time: Date, title: String, type: TourEventType, location: String? = nil, notes: String? = nil, busOrSeatInfo: String? = nil) {
        self.time = time
        self.title = title
        self.typeRaw = type.rawValue
        self.location = location
        self.notes = notes
        self.busOrSeatInfo = busOrSeatInfo
    }

    var type: TourEventType {
        get { TourEventType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}
