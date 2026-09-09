import SwiftUI
import SwiftData

/// Basis-Einstellungen. Team-Sync (Supabase) ist als spätere Ausbaustufe vorgesehen (§28).
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var concerts: [Concert]
    @Query private var contentItems: [ContentItem]
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("Über") {
                LabeledContent("App", value: "TKC Content Hub")
                LabeledContent("Version", value: "1.0 (MVP)")
                LabeledContent("Konzerte gespeichert", value: "\(concerts.count)")
                LabeledContent("Content-Einträge", value: "\(contentItems.count)")
            }

            Section("Datenquelle") {
                Text(ConcertSyncService.sourceURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Alle Daten zurücksetzen", role: .destructive) {
                    showingResetConfirmation = true
                }
            } footer: {
                Text("Löscht alle Konzerte, Content-Einträge, Assets und Library-Einträge unwiderruflich von diesem Gerät.")
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
}
