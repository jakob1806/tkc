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
    /// Destruktive Massenaktionen (z.B. alle Daten zurücksetzen) nur für Freigeber.
    var canResetData: Bool { self == .approver }
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
        didSet { KeychainStore.write(supabaseAnonKey, for: Keys.supabaseAnonKey) }
    }

    var remindersEnabled: Bool {
        didSet { UserDefaults.standard.set(remindersEnabled, forKey: Keys.remindersEnabled) }
    }

    var teamSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(teamSyncEnabled, forKey: Keys.teamSyncEnabled) }
    }

    /// Für den "Chor Assistant" (§KI-Konzept). Wird ausschließlich lokal auf dem Gerät
    /// eingegeben und gespeichert - verlässt das Gerät nur direkt Richtung Gemini-API.
    var geminiAPIKey: String {
        didSet { KeychainStore.write(geminiAPIKey, for: Keys.geminiAPIKey) }
    }

    /// Social Analytics (§29): URL des eigenen Backends, das die OAuth-Tokens hält und die
    /// vier Plattform-APIs aufruft. Ohne Backend bleiben die Provider Stubs.
    var socialAnalyticsBackendURL: String {
        didSet { UserDefaults.standard.set(socialAnalyticsBackendURL, forKey: Keys.socialBackendURL) }
    }

    /// §5 Sync-Kadenz, in Stunden - konfigurierbar wie im Konzept gefordert.
    var socialSyncIntervalUnder48h: Double {
        didSet { UserDefaults.standard.set(socialSyncIntervalUnder48h, forKey: Keys.syncUnder48h) }
    }
    var socialSyncInterval2to7Days: Double {
        didSet { UserDefaults.standard.set(socialSyncInterval2to7Days, forKey: Keys.sync2to7Days) }
    }
    var socialSyncInterval7to30Days: Double {
        didSet { UserDefaults.standard.set(socialSyncInterval7to30Days, forKey: Keys.sync7to30Days) }
    }
    var socialSyncIntervalOver30Days: Double {
        didSet { UserDefaults.standard.set(socialSyncIntervalOver30Days, forKey: Keys.syncOver30Days) }
    }

    private enum Keys {
        static let role = "appSettings.role"
        static let displayName = "appSettings.displayName"
        static let supabaseURL = "appSettings.supabaseURL"
        static let supabaseAnonKey = "appSettings.supabaseAnonKey"
        static let teamSyncEnabled = "appSettings.teamSyncEnabled"
        static let remindersEnabled = "appSettings.remindersEnabled"
        static let geminiAPIKey = "appSettings.geminiAPIKey"
        static let socialBackendURL = "appSettings.socialAnalyticsBackendURL"
        static let syncUnder48h = "appSettings.socialSyncIntervalUnder48h"
        static let sync2to7Days = "appSettings.socialSyncInterval2to7Days"
        static let sync7to30Days = "appSettings.socialSyncInterval7to30Days"
        static let syncOver30Days = "appSettings.socialSyncIntervalOver30Days"
    }

    /// Liest ein Geheimnis aus der Keychain; ein früher in UserDefaults abgelegter Wert wird
    /// einmalig übernommen und aus UserDefaults entfernt.
    private static func migratedSecret(_ key: String, defaults: UserDefaults) -> String {
        if let stored = KeychainStore.read(key) { return stored }
        if let legacy = defaults.string(forKey: key), !legacy.isEmpty {
            KeychainStore.write(legacy, for: key)
            defaults.removeObject(forKey: key)
            return legacy
        }
        return ""
    }

    private init() {
        let defaults = UserDefaults.standard
        currentRole = AppRole(rawValue: defaults.string(forKey: Keys.role) ?? "") ?? .editor
        displayName = defaults.string(forKey: Keys.displayName) ?? ""
        supabaseURL = defaults.string(forKey: Keys.supabaseURL) ?? ""
        supabaseAnonKey = Self.migratedSecret(Keys.supabaseAnonKey, defaults: defaults)
        teamSyncEnabled = defaults.bool(forKey: Keys.teamSyncEnabled)
        remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
        geminiAPIKey = Self.migratedSecret(Keys.geminiAPIKey, defaults: defaults)
        socialAnalyticsBackendURL = defaults.string(forKey: Keys.socialBackendURL) ?? ""
        socialSyncIntervalUnder48h = defaults.object(forKey: Keys.syncUnder48h) as? Double ?? 2
        socialSyncInterval2to7Days = defaults.object(forKey: Keys.sync2to7Days) as? Double ?? 6
        socialSyncInterval7to30Days = defaults.object(forKey: Keys.sync7to30Days) as? Double ?? 24
        socialSyncIntervalOver30Days = defaults.object(forKey: Keys.syncOver30Days) as? Double ?? 72
    }
}
