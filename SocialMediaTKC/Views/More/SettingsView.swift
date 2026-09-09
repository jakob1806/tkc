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
                Text("„Nur lesend“ blendet Bearbeiten/Löschen/Freigeben aus. „Freigeber“ kann zusätzlich den Freigabestatus ändern. Läuft aktuell nur lokal auf diesem Gerät.")
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

            Section("Datenquelle") {
                Text(ConcertSyncService.sourceURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if settings.currentRole.canDelete {
                Section {
                    Button("Alle Daten zurücksetzen", role: .destructive) {
                        showingResetConfirmation = true
                    }
                } footer: {
                    Text("Löscht alle Konzerte, Content-Einträge, Assets und Library-Einträge unwiderruflich von diesem Gerät.")
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
        for item in contentItems { context.delete(item) }
        for concert in concerts { context.delete(concert) }
        try? context.save()
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
