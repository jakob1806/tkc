import SwiftUI

/// Die vier unterstützten Social-Analytics-Kanäle. Bewusst als eigenes, schlankes Enum
/// getrennt vom bestehenden `Platform` (Content-Planung kennt auch Story/Reel/Website als
/// eigene "Plattformen" für die Redaktionsplanung - Social Analytics rechnet dagegen auf
/// Account-Ebene). Instagram und Facebook bleiben trotz gemeinsamer Meta-API getrennt
/// modelliert, weil sich ihre Post-Typen und verfügbaren Insights unterscheiden.
enum SocialPlatform: String, Codable, CaseIterable, Identifiable {
    case instagram, facebook, tiktok, youtube

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        }
    }

    var symbol: String {
        switch self {
        case .instagram: return "camera.fill"
        case .facebook: return "f.circle.fill"
        case .tiktok: return "music.note"
        case .youtube: return "play.rectangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .instagram: return .pink
        case .facebook: return .blue
        case .tiktok: return .primary
        case .youtube: return .red
        }
    }
}

/// Post-Typ je Plattform (§12 Filter: Reels/Videos/Posts/Shorts je nach Plattform).
enum SocialPostType: String, Codable, CaseIterable, Identifiable {
    case feedPost, reel, story, video, short, tiktokVideo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .feedPost: return "Post"
        case .reel: return "Reel"
        case .story: return "Story"
        case .video: return "Video"
        case .short: return "Short"
        case .tiktokVideo: return "TikTok Video"
        }
    }

    static func availableTypes(for platform: SocialPlatform) -> [SocialPostType] {
        switch platform {
        case .instagram: return [.feedPost, .reel, .story]
        case .facebook: return [.feedPost, .reel, .video]
        case .tiktok: return [.tiktokVideo]
        case .youtube: return [.video, .short]
        }
    }
}
