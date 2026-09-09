import SwiftUI

enum Platform: String, Codable, CaseIterable, Identifiable {
    /// Instagram und Facebook laufen für die Contentplanung bewusst als eine Plattform,
    /// weil ein Beitrag über Meta praktisch immer 1:1 auf beiden landet (anders als im
    /// Social-Analytics-Modul, wo Post-Typen und Insights sich unterscheiden und die
    /// beiden deshalb getrennt bleiben).
    case instagram, instagramStory, instagramReel, tiktok, youtube, youtubeShorts, whatsapp, website

    /// Alte gespeicherte Werte ("facebook") fallen automatisch auf `.instagram` zurück.
    init?(rawValue: String) {
        switch rawValue {
        case "instagram": self = .instagram
        case "instagramStory": self = .instagramStory
        case "instagramReel": self = .instagramReel
        case "tiktok": self = .tiktok
        case "youtube": self = .youtube
        case "youtubeShorts": self = .youtubeShorts
        case "whatsapp": self = .whatsapp
        case "website": self = .website
        case "facebook": self = .instagram
        default: return nil
        }
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram & Facebook"
        case .instagramStory: return "Instagram Story"
        case .instagramReel: return "Instagram Reel"
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        case .youtubeShorts: return "YouTube Shorts"
        case .whatsapp: return "WhatsApp-Kanal"
        case .website: return "Website"
        }
    }

    var symbol: String {
        switch self {
        case .instagram, .instagramStory, .instagramReel: return "camera.fill"
        case .tiktok: return "music.note"
        case .youtube, .youtubeShorts: return "play.rectangle.fill"
        case .whatsapp: return "message.fill"
        case .website: return "globe"
        }
    }

    var color: Color {
        switch self {
        case .instagram, .instagramStory, .instagramReel: return .pink
        case .tiktok: return .black
        case .youtube, .youtubeShorts: return .red
        case .whatsapp: return .green
        case .website: return .indigo
        }
    }
}

enum ContentType: String, Codable, CaseIterable, Identifiable {
    case feedPost, story, reel, tiktokVideo, short, newsletter, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .feedPost: return "Feed Post"
        case .story: return "Story"
        case .reel: return "Reel"
        case .tiktokVideo: return "TikTok"
        case .short: return "Short"
        case .newsletter: return "Newsletter"
        case .other: return "Sonstiges"
        }
    }

    var symbol: String {
        switch self {
        case .feedPost: return "square.grid.2x2"
        case .story: return "circle.dashed"
        case .reel, .tiktokVideo, .short: return "video.fill"
        case .newsletter: return "envelope.fill"
        case .other: return "ellipsis.circle"
        }
    }

    /// Plattform kodiert die Art oft schon (z.B. "Instagram Story", "YouTube Shorts") -
    /// hier wird die Auswahl auf das eingeschränkt, was zur gewählten Plattform tatsächlich
    /// passt, statt bei jedem Content immer die volle, größtenteils irrelevante Liste zu zeigen.
    static func availableTypes(for platform: Platform) -> [ContentType] {
        switch platform {
        case .instagram: return [.feedPost]
        case .instagramStory: return [.story]
        case .instagramReel: return [.reel]
        case .tiktok: return [.tiktokVideo]
        case .youtube: return [.other]
        case .youtubeShorts: return [.short]
        case .whatsapp: return [.newsletter, .other]
        case .website: return [.newsletter, .other]
        }
    }
}

enum ContentStatus: String, Codable, CaseIterable, Identifiable {
    case idea, planned, materialMissing, inProgress, approvalNeeded, approved, scheduled, published, discarded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .idea: return "Idee"
        case .planned: return "Geplant"
        case .materialMissing: return "Material fehlt"
        case .inProgress: return "In Bearbeitung"
        case .approvalNeeded: return "Freigabe nötig"
        case .approved: return "Freigegeben"
        case .scheduled: return "Geplant/Veröffentlicht"
        case .published: return "Veröffentlicht"
        case .discarded: return "Verworfen"
        }
    }

    var color: Color {
        switch self {
        case .idea: return .gray
        case .planned: return .blue
        case .materialMissing: return .orange
        case .inProgress: return .purple
        case .approvalNeeded: return .yellow
        case .approved: return .mint
        case .scheduled: return .teal
        case .published: return .green
        case .discarded: return .red
        }
    }

    /// Board-Spalten-Reihenfolge (§8)
    static var boardColumns: [ContentStatus] {
        [.idea, .planned, .inProgress, .approvalNeeded, .approved, .published]
    }
}

enum Priority: Int, Codable, CaseIterable, Identifiable, Comparable {
    case low = 0, medium = 1, high = 2

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool { lhs.rawValue < rhs.rawValue }
}

enum ApprovalStatus: String, Codable, CaseIterable, Identifiable {
    case draft, requested, changesNeeded, approved

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft: return "Entwurf"
        case .requested: return "Freigabe angefragt"
        case .changesNeeded: return "Änderung erforderlich"
        case .approved: return "Freigegeben"
        }
    }
}

enum AssetType: String, Codable, CaseIterable, Identifiable {
    case photo, video, graphic, canvaLink, driveLink, audio, document

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .photo: return "Foto"
        case .video: return "Video"
        case .graphic: return "Grafik"
        case .canvaLink: return "Canva Link"
        case .driveLink: return "Drive/Dropbox Link"
        case .audio: return "Audio"
        case .document: return "Dokument"
        }
    }

    var symbol: String {
        switch self {
        case .photo: return "photo"
        case .video: return "video"
        case .graphic: return "paintbrush"
        case .canvaLink: return "link"
        case .driveLink: return "externaldrive.badge.icloud"
        case .audio: return "waveform"
        case .document: return "doc.text"
        }
    }
}

/// Relative Bindung von Content an ein Konzert (§ Ergänzung: verschiebt sich automatisch mit dem Konzerttermin)
enum RelativeOffsetUnit: String, Codable {
    case daysBefore, sameDay, daysAfter
}

struct RelativeOffset: Codable, Hashable {
    var unit: RelativeOffsetUnit
    var days: Int
    /// Optionale feste Uhrzeit relativ zum Tag (z.B. 12:00 Uhr vormittags am Konzerttag)
    var hour: Int
    var minute: Int

    static let saveTheDate21 = RelativeOffset(unit: .daysBefore, days: 21, hour: 12, minute: 0)
    static let announcement14 = RelativeOffset(unit: .daysBefore, days: 14, hour: 12, minute: 0)
    static let reel7 = RelativeOffset(unit: .daysBefore, days: 7, hour: 18, minute: 0)
    static let ticketReminder3 = RelativeOffset(unit: .daysBefore, days: 3, hour: 12, minute: 0)
    static let tomorrowStory1 = RelativeOffset(unit: .daysBefore, days: 1, hour: 18, minute: 0)
    static let tonightMorning = RelativeOffset(unit: .sameDay, days: 0, hour: 10, minute: 0)
    static let behindTheScenes = RelativeOffset(unit: .sameDay, days: 0, hour: 15, minute: 0)
    static let concertEvening = RelativeOffset(unit: .sameDay, days: 0, hour: 19, minute: 0)
    static let thankYou1 = RelativeOffset(unit: .daysAfter, days: 1, hour: 12, minute: 0)
    static let recap5 = RelativeOffset(unit: .daysAfter, days: 5, hour: 18, minute: 0)

    /// Berechnet das tatsächliche Datum relativ zum Konzerttermin.
    func resolvedDate(relativeTo concertDate: Date, calendar: Calendar = .current) -> Date {
        let dayDelta: Int
        switch unit {
        case .daysBefore: dayDelta = -days
        case .sameDay: dayDelta = 0
        case .daysAfter: dayDelta = days
        }
        let baseDay = calendar.date(byAdding: .day, value: dayDelta, to: concertDate) ?? concertDate
        var components = calendar.dateComponents([.year, .month, .day], from: baseDay)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? baseDay
    }
}
