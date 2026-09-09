import SwiftUI

/// Einfaches Rollenmodell für den Team-Betrieb (Erweiterung zu §14/§28).
/// Läuft lokal auf diesem Gerät; sobald das Supabase-Backend angebunden ist, sollte die Rolle
/// serverseitig je Account hinterlegt werden statt nur clientseitig.
enum AppRole: String, CaseIterable, Identifiable, Codable {
    case editor, approver, viewer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .editor: return "Redaktion"
        case .approver: return "Freigeber"
        case .viewer: return "Nur lesend"
        }
    }

    var symbol: String {
        switch self {
        case .editor: return "pencil"
        case .approver: return "checkmark.seal"
        case .viewer: return "eye"
        }
    }

    var canEdit: Bool { self != .viewer }
    var canApprove: Bool { self == .approver }
    var canDelete: Bool { self != .viewer }
}

/// Zentrale, app-weite Einstellungen (Rolle, Anzeigename, Supabase-Konfiguration).
@Observable
final class AppSettings {
    static let shared = AppSettings()

    var currentRole: AppRole {
        didSet { UserDefaults.standard.set(currentRole.rawValue, forKey: Keys.role) }
    }

    var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: Keys.displayName) }
    }

    var supabaseURL: String {
        didSet { UserDefaults.standard.set(supabaseURL, forKey: Keys.supabaseURL) }
    }

    var supabaseAnonKey: String {
        didSet { UserDefaults.standard.set(supabaseAnonKey, forKey: Keys.supabaseAnonKey) }
    }

    var teamSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(teamSyncEnabled, forKey: Keys.teamSyncEnabled) }
    }

    /// Für den "Chor Assistant" (§KI-Konzept). Wird ausschließlich lokal auf dem Gerät
    /// eingegeben und gespeichert - verlässt das Gerät nur direkt Richtung Gemini-API.
    var geminiAPIKey: String {
        didSet { UserDefaults.standard.set(geminiAPIKey, forKey: Keys.geminiAPIKey) }
    }

    private enum Keys {
        static let role = "appSettings.role"
        static let displayName = "appSettings.displayName"
        static let supabaseURL = "appSettings.supabaseURL"
        static let supabaseAnonKey = "appSettings.supabaseAnonKey"
        static let teamSyncEnabled = "appSettings.teamSyncEnabled"
        static let geminiAPIKey = "appSettings.geminiAPIKey"
    }

    private init() {
        let defaults = UserDefaults.standard
        currentRole = AppRole(rawValue: defaults.string(forKey: Keys.role) ?? "") ?? .editor
        displayName = defaults.string(forKey: Keys.displayName) ?? ""
        supabaseURL = defaults.string(forKey: Keys.supabaseURL) ?? ""
        supabaseAnonKey = defaults.string(forKey: Keys.supabaseAnonKey) ?? ""
        teamSyncEnabled = defaults.bool(forKey: Keys.teamSyncEnabled)
        geminiAPIKey = defaults.string(forKey: Keys.geminiAPIKey) ?? ""
    }
}
