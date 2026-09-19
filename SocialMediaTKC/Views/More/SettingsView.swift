import SwiftUI
import SwiftData

/// Basis-Einstellungen inkl. Rolle/Team-Betrieb und Supabase-Team-Sync (§28-Ausbaustufe).
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var concerts: [Concert]
    @Query private var contentItems: [ContentItem]
    @State private var showingResetConfirmation = false
    @State private var settings = AppSettings.shared
    @State private var syncStatus: String?
    @State private var isSyncing = false

    var body: some View {
        Form {
            Section("Über") {
                LabeledContent("App", value: "TKC Content Hub")
                LabeledContent("Version", value: "1.0 (MVP)")
                LabeledContent("Konzerte gespeichert", value: "\(concerts.count)")
                LabeledContent("Content-Einträge", value: "\(contentItems.count)")
            }

            Section {
                TextField("Dein Name", text: $settings.displayName)
                Picker("Rolle", selection: $settings.currentRole) {
                    ForEach(AppRole.allCases) { role in
                        Label(role.displayName, systemImage: role.symbol).tag(role)
                    }
                }
            } header: {
                Text("Team-Rolle")
            } footer: {
                Text("„Nur lesend“ blendet Bearbeiten/Löschen/Freigeben aus. „Freigeber“ kann zusätzlich den Freigabestatus ändern. Läuft aktuell nur lokal auf diesem Gerät und ist kein Zugriffsschutz - dafür wäre Supabase-Auth nötig.")
            }

            Section {
                Toggle("Erinnerungen", isOn: Binding(
                    get: { settings.remindersEnabled },
                    set: { newValue in
                        settings.remindersEnabled = newValue
                        Task {
                            if newValue { settings.remindersEnabled = await ReminderService.requestAuthorization() }
                            await ReminderService.rescheduleAll(context: context)
                        }
                    }
                ))
            } header: {
                Text("Benachrichtigungen")
            } footer: {
                Text("Erinnert zum geplanten Veröffentlichungszeitpunkt und am Vortag eines Konzerts um 18:00 Uhr.")
            }

            Section {
                Toggle("Team-Sync aktivieren", isOn: $settings.teamSyncEnabled)
                if settings.teamSyncEnabled {
                    TextField("Supabase-URL", text: $settings.supabaseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Supabase Anon Key", text: $settings.supabaseAnonKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button {
                        Task { await syncNow() }
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Label("Jetzt synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(settings.supabaseURL.isEmpty || settings.supabaseAnonKey.isEmpty || isSyncing)
                    if let syncStatus {
                        Text(syncStatus).font(.caption).foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Team-Sync (Supabase)")
            } footer: {
                Text("Für die gemeinsame Bearbeitung im Team. Konzerte und Content-Einträge werden dann zusätzlich in Supabase gespiegelt, statt nur lokal auf diesem Gerät zu liegen. Siehe SUPABASE_SETUP.md im Repo für die Tabellen.")
            }

            Section {
                SecureField("Gemini API-Key", text: $settings.geminiAPIKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Chor Assistant (Gemini)")
            } footer: {
                Text("Der Key liegt verschlüsselt in der Keychain dieses Geräts und wird nur direkt an die Gemini-API gesendet. Kostenlosen Key unter aistudio.google.com/apikey erzeugen.")
            }

            Section {
                TextField("Backend-URL", text: $settings.socialAnalyticsBackendURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Stepper("Unter 48h: alle \(Int(settings.socialSyncIntervalUnder48h))h", value: $settings.socialSyncIntervalUnder48h, in: 1...24)
                Stepper("2-7 Tage: alle \(Int(settings.socialSyncInterval2to7Days))h", value: $settings.socialSyncInterval2to7Days, in: 1...48)
                Stepper("7-30 Tage: alle \(Int(settings.socialSyncInterval7to30Days))h", value: $settings.socialSyncInterval7to30Days, in: 6...168)
                Stepper("Über 30 Tage: alle \(Int(settings.socialSyncIntervalOver30Days))h", value: $settings.socialSyncIntervalOver30Days, in: 24...720)
            } header: {
                Text("Social Analytics")
            } footer: {
                Text("Die vier Plattform-Connectoren (Instagram/Facebook/TikTok/YouTube) rufen kein Secret direkt auf, sondern dieses Backend. Ohne hinterlegte URL bleiben Posts/Accounts nur manuell erfassbar. Details in SOCIAL_ANALYTICS_SETUP.md.")
            }

            Section("Datenquelle") {
                Text(ConcertSyncService.sourceURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if settings.currentRole.canResetData {
                Section {
                    Button("Alle Daten zurücksetzen", role: .destructive) {
                        showingResetConfirmation = true
                    }
                } footer: {
                    Text("Löscht alle Konzerte, Content, Projekte, Touren, Sänger, Dokumente, Library-Einträge und Social-Analytics-Daten unwiderruflich von diesem Gerät. Nur für Freigeber.")
                }
            }
        }
        .navigationTitle("Einstellungen")
        .confirmationDialog("Wirklich alle Daten löschen?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { resetAllData() }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func resetAllData() {
        do {
            try deleteAll(ContentItem.self)
            try deleteAll(Concert.self)
            try deleteAll(LibraryItem.self)
            try deleteAll(Project.self)
            try deleteAll(Singer.self)
            try deleteAll(Document.self)
            try deleteAll(SocialAccount.self)
            try deleteAll(SocialPost.self)
            try context.save()
            UserDefaults.standard.removeObject(forKey: "concertSync.deletedExternalIds")
            UserDefaults.standard.removeObject(forKey: "concertSync.lastSuccessAt")
        } catch {
            syncStatus = "Zurücksetzen fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    /// Einzeln löschen statt Batch-Delete, damit die Kaskaden-Regeln der Relationships greifen.
    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        for object in try context.fetch(FetchDescriptor<T>()) { context.delete(object) }
    }

    private func syncNow() async {
        isSyncing = true
        defer { isSyncing = false }
        do {
            let result = try await SupabaseSyncService.syncAll(context: context)
            syncStatus = "Erfolgreich synchronisiert: \(result.concertsPushed) Konzerte, \(result.contentItemsPushed) Content-Einträge hochgeladen."
        } catch {
            syncStatus = "Fehler: \(error.localizedDescription)"
        }
    }
}
