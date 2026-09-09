import SwiftUI
import SwiftData

@main
struct SocialMediaTKCApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Concert.self, ContentItem.self, Asset.self, ContentTask.self,
            ContentTemplate.self, ContentTemplateItem.self, LibraryItem.self, Comment.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData ModelContainer konnte nicht erstellt werden: \(error)")
        }
        ContentTemplate.seedBuiltInTemplates(in: modelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
