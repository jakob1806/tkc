import SwiftUI

struct RootTabView: View {
    @State private var showingNewContent = false
    @State private var selectedTab: Tab = .today
    var settings = AppSettings.shared

    enum Tab: Hashable {
        case today, calendar, concerts, board, more
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem { Label("Heute", systemImage: "sun.max.fill") }
                    .tag(Tab.today)

                CalendarContainerView()
                    .tabItem { Label("Kalender", systemImage: "calendar") }
                    .tag(Tab.calendar)

                ConcertListView()
                    .tabItem { Label("Konzerte", systemImage: "music.mic") }
                    .tag(Tab.concerts)

                ContentBoardView()
                    .tabItem { Label("Board", systemImage: "square.grid.3x3.fill") }
                    .tag(Tab.board)

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
