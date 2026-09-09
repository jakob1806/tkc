import Foundation
import SwiftData

/// Ein verbundener Account auf einer der vier Plattformen (§3 Datenmodell).
/// `connected` unterscheidet einen Account mit gültigem OAuth-Token vom nur-lokal
/// angelegten Platzhalter (solange kein Backend angebunden ist).
@Model
final class SocialAccount {
    var platformRaw: String
    var externalAccountId: String
    var username: String
    var displayName: String
    var profileImageURL: String?
    var followerCount: Int?
    var connected: Bool
    var lastSyncedAt: Date?
    var lastSyncErrorRaw: String?

    @Relationship(deleteRule: .cascade, inverse: \SocialPost.account)
    var posts: [SocialPost] = []

    @Relationship(deleteRule: .cascade, inverse: \FollowerSnapshot.account)
    var followerSnapshots: [FollowerSnapshot] = []

    init(
        platform: SocialPlatform,
        externalAccountId: String,
        username: String,
        displayName: String,
        profileImageURL: String? = nil,
        followerCount: Int? = nil,
        connected: Bool = false
    ) {
        self.platformRaw = platform.rawValue
        self.externalAccountId = externalAccountId
        self.username = username
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.followerCount = followerCount
        self.connected = connected
    }

    var platform: SocialPlatform {
        get { SocialPlatform(rawValue: platformRaw) ?? .instagram }
        set { platformRaw = newValue.rawValue }
    }

    var lastSyncError: SocialSyncError? {
        get { lastSyncErrorRaw.flatMap(SocialSyncError.init(rawValue:)) }
        set { lastSyncErrorRaw = newValue?.rawValue }
    }
}

/// §26 Followerentwicklung: eigener Zeitreihen-Strang, unabhängig von einzelnen Posts.
@Model
final class FollowerSnapshot {
    var capturedAt: Date
    var followerCount: Int

    var account: SocialAccount?

    init(capturedAt: Date = .now, followerCount: Int) {
        self.capturedAt = capturedAt
        self.followerCount = followerCount
    }
}

/// §30 Fehlerfälle - niemals stillschweigend als 0/leer behandeln, sondern explizit benennen.
enum SocialSyncError: String, Codable {
    case tokenExpired
    case missingPermission
    case rateLimited
    case platformUnreachable
    case postDeleted
    case accountDisconnected

    var displayName: String {
        switch self {
        case .tokenExpired: return "Anmeldung abgelaufen"
        case .missingPermission: return "Fehlende API-Berechtigung"
        case .rateLimited: return "API-Limit erreicht"
        case .platformUnreachable: return "Plattform nicht erreichbar"
        case .postDeleted: return "Beitrag wurde gelöscht"
        case .accountDisconnected: return "Account getrennt"
        }
    }
}
