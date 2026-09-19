import SwiftUI
import SwiftData

@main
struct SocialMediaTKCApp: App {
    private static let schema = Schema([
        Concert.self, ContentItem.self, Asset.self, ContentTask.self,
        ContentTemplate.self, ContentTemplateItem.self, LibraryItem.self, Comment.self,
        Project.self, Tour.self, TourDay.self, TourEvent.self,
        Singer.self, CastAssignment.self, Document.self,
        SocialAccount.self, FollowerSnapshot.self, SocialPost.self, SocialMetricSnapshot.self,
    ])

    private let modelContainer: ModelContainer?
    @State private var startupError: String?

    init() {
        let configuration = ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: Self.schema, configurations: [configuration])
            ContentTemplate.seedBuiltInTemplates(in: container.mainContext)
            modelContainer = container
        } catch {
            modelContainer = nil
            _startupError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                RootTabView()
                    .modelContainer(modelContainer)
            } else {
                StartupErrorView(message: startupError ?? "Unbekannter Fehler")
            }
        }
    }
}

/// Wird statt eines Absturzes gezeigt, wenn die lokale Datenbank nicht geöffnet werden kann
/// (z.B. nach einer fehlgeschlagenen Migration). Die alte Datenbank wird nur beiseitegelegt,
/// nicht gelöscht.
private struct StartupErrorView: View {
    let message: String
    @State private var didBackup = false
    @State private var backupError: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill").font(.largeTitle).foregroundStyle(.orange)
            Text("Datenbank konnte nicht geöffnet werden").font(.headline)
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if didBackup {
                Text("Die alte Datenbank wurde gesichert. Bitte die App jetzt beenden und neu starten - es wird eine neue, leere Datenbank angelegt; die Konzerte kommen per Sync zurück.")
                    .font(.callout).multilineTextAlignment(.center)
            } else {
                Button("Alte Datenbank sichern und neu beginnen") { backupStore() }
                    .buttonStyle(.borderedProminent)
            }
            if let backupError { Text(backupError).font(.caption).foregroundStyle(.red) }
        }
        .padding()
    }

    private func backupStore() {
        let fm = FileManager.default
        guard let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let stamp = Int(Date.now.timeIntervalSince1970)
        do {
            for name in try fm.contentsOfDirectory(atPath: support.path) where name.hasPrefix("default.store") {
                try fm.moveItem(at: support.appendingPathComponent(name), to: support.appendingPathComponent("backup-\(stamp)-\(name)"))
            }
            didBackup = true
        } catch {
            backupError = error.localizedDescription
        }
    }
}
