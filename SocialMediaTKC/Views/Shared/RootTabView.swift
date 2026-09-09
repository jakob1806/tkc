import SwiftUI

/// Navigation gemäß Choir-Operations-System-Konzept: Home · Kalender · Projekte · Chor · Mehr.
/// Konzerte/Content Board/Ideen/Templates/etc. sind darunter erreichbar, statt eigene Tabs zu
/// beanspruchen - Content ist nur noch eines der Werkzeuge, nicht mehr die Hauptachse.
struct RootTabView: View {
    @State private var showingNewContent = false
    @State private var selectedTab: Tab = .home
    var settings = AppSettings.shared

    enum Tab: Hashable {
        case home, calendar, projects, choir, more
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

                ChoirRosterView()
                    .tabItem { Label("Chor", systemImage: "person.3.fill") }
                    .tag(Tab.choir)

                MoreView()
                    .tabItem { Label("Mehr", systemImage: "ellipsis.circle.fill") }
                    .tag(Tab.more)
            }

            if settings.currentRole.canEdit {
                Button {
                    showingNewContent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 6, y: 3)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 68)
                .accessibilityLabel("Neuer Content")
            }
        }
        .sheet(isPresented: $showingNewContent) {
            ContentEditorView(concert: nil)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Concert.self, ContentItem.self], inMemory: true)
}
