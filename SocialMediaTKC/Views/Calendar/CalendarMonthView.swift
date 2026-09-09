import SwiftUI
import SwiftData

/// §2 Hauptansicht - Monatskalender mit farbigen Indikatoren pro Tag.
struct CalendarMonthView: View {
    @Query(sort: \ContentItem.date) private var allContent: [ContentItem]
    @Query(sort: \Concert.date) private var allConcerts: [Concert]

    @State private var visibleMonth: Date = Calendar.germanCurrent.startOfMonth(for: .now)
    @State private var selectedDay: Date?
    @State private var searchText = ""

    private let calendar = Calendar.germanCurrent

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                weekdayHeader
                monthGrid
                Spacer(minLength: 0)
            }
            .navigationTitle(visibleMonth.formatted(Date.FormatStyle(locale: .german).month(.wide).year()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Heute") { withAnimation { visibleMonth = calendar.startOfMonth(for: .now) } }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Label("Filter folgen in Kürze", systemImage: "line.3.horizontal.decrease.circle")
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Content, Konzerte, Orte…")
            .sheet(item: Binding(get: { selectedDay.map(DayBoxed.init) }, set: { selectedDay = $0?.date })) { boxed in
                DayDetailSheet(day: boxed.date, items: items(on: boxed.date), concerts: concerts(on: boxed.date))
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private struct DayBoxed: Identifiable {
        let date: Date
        var id: Date { date }
    }

    private var header: some View {
        HStack {
            Button { withAnimation { visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth)! } } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(visibleMonth.formatted(Date.FormatStyle(locale: .german).month(.wide).year()))
                .font(.headline)
            Spacer()
            Button { withAnimation { visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth)! } } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbolsMondayFirst, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }

    private var monthGrid: some View {
        let days = calendar.daysGridForMonth(containing: visibleMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { day in
                if calendar.isDate(day, equalTo: visibleMonth, toGranularity: .month) {
                    DayCell(
                        day: day,
                        isToday: calendar.isDateInToday(day),
                        items: items(on: day),
                        concerts: concerts(on: day)
                    )
                    .onTapGesture { selectedDay = day }
                } else {
                    Color.clear.frame(height: 56)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func items(on day: Date) -> [ContentItem] {
        allContent.filter { !$0.isUnplanned && calendar.isDate($0.date, inSameDayAs: day) }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private func concerts(on day: Date) -> [Concert] {
        allConcerts.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }
}

private struct DayCell: View {
    let day: Date
    let isToday: Bool
    let items: [ContentItem]
    let concerts: [Concert]

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .frame(width: 28, height: 28)
                .background(isToday ? Color.accentColor : .clear, in: Circle())
                .foregroundStyle(isToday ? .white : .primary)

            HStack(spacing: 2) {
                if !concerts.isEmpty {
                    Circle().fill(.orange).frame(width: 5, height: 5)
                }
                ForEach(Array(Set(items.map(\.platform))).prefix(3), id: \.self) { platform in
                    Circle().fill(platform.color).frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .contentShape(Rectangle())
    }
}

private struct DayDetailSheet: View {
    let day: Date
    let items: [ContentItem]
    let concerts: [Concert]
    @State private var showingNewContent = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(concerts) { concert in
                    NavigationLink {
                        ConcertDetailView(concert: concert)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text(concert.title).font(.headline)
                                Text(concert.venue).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Text("🎵")
                        }
                    }
                }
                ForEach(items.sorted(by: { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) })) { item in
                    NavigationLink {
                        ContentDetailView(item: item)
                    } label: {
                        HStack {
                            Image(systemName: item.contentType.symbol)
                                .foregroundStyle(item.platform.color)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                if let time = item.publishTime {
                                    Text(time.formatted(date: .omitted, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.status.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(item.status.color.opacity(0.15), in: Capsule())
                                .foregroundStyle(item.status.color)
                        }
                    }
                }
                if items.isEmpty && concerts.isEmpty {
                    ContentUnavailableView("Kein Content geplant", systemImage: "calendar.badge.plus")
                }
            }
            .navigationTitle(day.formatted(date: .long, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewContent = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNewContent) {
                ContentEditorView(concert: concerts.first)
            }
        }
    }
}

extension Calendar {
    /// Deutsche Locale unabhängig von der Geräte-Systemsprache, da die App durchgängig auf Deutsch ausgelegt ist.
    static var germanCurrent: Calendar {
        var calendar = Calendar.current
        calendar.locale = .german
        return calendar
    }

    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }

    /// 6x7-Raster inkl. Vor-/Nachmonatstagen, Woche beginnt Montag.
    func daysGridForMonth(containing date: Date) -> [Date] {
        let start = startOfMonth(for: date)
        let weekday = component(.weekday, from: start) // 1 = Sonntag
        let mondayOffset = (weekday + 5) % 7
        let gridStart = self.date(byAdding: .day, value: -mondayOffset, to: start)!
        return (0..<42).compactMap { self.date(byAdding: .day, value: $0, to: gridStart) }
    }

    var shortWeekdaySymbolsMondayFirst: [String] {
        let symbols = veryShortWeekdaySymbols
        return Array(symbols[1...] + symbols[0...0])
    }
}
