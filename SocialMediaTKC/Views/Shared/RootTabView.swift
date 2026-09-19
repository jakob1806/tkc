import SwiftUI
import SwiftData

/// Navigation: Home · Kalender · Projekte · Analyse · Mehr.
/// Besetzung (Chor) ist bewusst kein eigener Tab, sondern nur eine Funktion innerhalb
/// eines Projekts (ProjectCastView) - Verwaltung der Sänger-Stammdaten liegt unter Mehr.
struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingNewContent = false
    @State private var selectedTab: Tab = .home
    var settings = AppSettings.shared

    enum Tab: Hashable {
        case home, calendar, projects, analytics, more
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(Tab.home)

                CalendarContainerView()
                    .tabItem { Label("Kalender", systemImage: "calendar") }
                    .tag(Tab.calendar)

                ProjectListView()
                    .tabItem { Label("Projekte", systemImage: "folder.fill") }
                    .tag(Tab.projects)

                AnalyticsView()
                    .tabItem { Label("Analyse", systemImage: "chart.xyaxis.line") }
                    .tag(Tab.analytics)

                MoreView()
                    .tabItem { Label("Mehr", systemImage: "ellipsis.circle.fill") }
                    .tag(Tab.more)
            }
            .contentMargins(.bottom, settings.currentRole.canEdit ? 76 : 0, for: .scrollContent)

            if settings.currentRole.canEdit {
                Button {
                    showingNewContent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Theme.buttonGradient))
                        .shadow(color: Theme.brand.opacity(0.45), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 68)
                .accessibilityLabel("Neuer Content")
            }
        }
        .tint(Theme.brand)
        .sheet(isPresented: $showingNewContent) {
            ContentEditorView(concert: nil)
        }
        .task {
            await ConcertSyncService.syncIfStale(context: modelContext)
            await ReminderService.rescheduleAll(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await ConcertSyncService.syncIfStale(context: modelContext)
                    await ReminderService.rescheduleAll(context: modelContext)
                }
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Concert.self, ContentItem.self], inMemory: true)
}
