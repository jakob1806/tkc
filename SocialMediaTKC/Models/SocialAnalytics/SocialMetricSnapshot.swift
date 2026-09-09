import Foundation
import SwiftData

/// Ein Zeitpunkt-Snapshot der Kennzahlen eines Posts (§4 Historische Daten).
/// Jede Kennzahl ist optional - eine fehlende Kennzahl bedeutet "von dieser Plattform/
/// diesem Post nicht verfügbar", niemals 0 (§30).
@Model
final class SocialMetricSnapshot {
    var capturedAt: Date
    var views: Int?
    var likes: Int?
    var comments: Int?
    var shares: Int?
    var saves: Int?
    var reach: Int?
    var impressions: Int?
    var watchTimeMinutes: Double?
    var averageWatchTimeSeconds: Double?

    var post: SocialPost?

    init(
        capturedAt: Date = .now,
        views: Int? = nil,
        likes: Int? = nil,
        comments: Int? = nil,
        shares: Int? = nil,
        saves: Int? = nil,
        reach: Int? = nil,
        impressions: Int? = nil,
        watchTimeMinutes: Double? = nil,
        averageWatchTimeSeconds: Double? = nil
    ) {
        self.capturedAt = capturedAt
        self.views = views
        self.likes = likes
        self.comments = comments
        self.shares = shares
        self.saves = saves
        self.reach = reach
        self.impressions = impressions
        self.watchTimeMinutes = watchTimeMinutes
        self.averageWatchTimeSeconds = averageWatchTimeSeconds
    }

    func value(for metric: SocialMetric) -> Int? {
        switch metric {
        case .views: return views
        case .likes: return likes
        case .comments: return comments
        case .shares: return shares
        case .saves: return saves
        case .reach: return reach
        case .impressions: return impressions
        }
    }
}

/// §7/§8 Kennzahlen, die im Hauptdiagramm auswählbar sind.
enum SocialMetric: String, Codable, CaseIterable, Identifiable {
    case views, likes, comments, shares, saves, reach, impressions

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .views: return "Views"
        case .likes: return "Likes"
        case .comments: return "Kommentare"
        case .shares: return "Shares"
        case .saves: return "Saves"
        case .reach: return "Reichweite"
        case .impressions: return "Impressions"
        }
    }

    /// Die vier Hauptkennzahlen aus §7 (Reach/Impressions sind Zusatzkennzahlen je Plattform).
    static var primary: [SocialMetric] { [.views, .likes, .comments, .shares] }
}
