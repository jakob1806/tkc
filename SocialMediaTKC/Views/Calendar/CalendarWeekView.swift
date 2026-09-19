import SwiftUI
import SwiftData

/// §19 Wochenübersicht: visuell schnell erfassbare Detailansicht einer Woche.
struct CalendarWeekView: View {
    @Query(sort: \ContentItem.date) private var allContent: [ContentItem]
    @Query(sort: \Concert.date) private var allConcerts: [Concert]

    @State private var weekStart: Date
    @State private var showingNewContent = false
    @State private var newContentDay: Date?

    private let calendar = Calendar.current

    init() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let mondayOffset = (weekday + 5) % 7
        _weekStart = State(initialValue: calendar.date(byAdding: .day, value: -mondayOffset, to: today)!)
    }

    private var days: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { withAnimation { weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)! } } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(weekRangeLabel).font(.headline)
                Spacer()
                Button { withAnimation { weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)! } } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            List {
                ForEach(days, id: \.self) { day in
                    Section {
                        let concerts = allConcerts.filter { calendar.isDate($0.date, inSameDayAs: day) }
                        let items = allContent.filter { !$0.isUnplanned && calendar.isDate($0.date, inSameDayAs: day) }
                            .sorted { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) }

                        if concerts.isEmpty && items.isEmpty {
                            Text("—").foregroundStyle(.tertiary)
                        } else {
                            ForEach(concerts) { concert in
                                NavigationLink {
                                    ConcertDetailView(concert: concert)
                                } label: {
                                    Label(concert.title, systemImage: "music.mic").foregroundStyle(.orange)
                                }
                            }
                            ForEach(items) { item in
                                NavigationLink {
                                    ContentDetailView(item: item)
                                } label: {
                                    HStack {
                                        Circle().fill(item.platform.color).frame(width: 8, height: 8)
                                        Text(item.title)
                                        Spacer()
                                        if let time = item.publishTime {
                                            Text(time.formatted(date: .omitted, time: .shortened))
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(day.formatted(Date.FormatStyle(locale: .german).weekday(.wide)))
                            if calendar.isDateInToday(day) {
                                Text("Heute").font(.caption2).foregroundStyle(Color.accentColor)
                            }
                            Spacer()
                            Text(day.formatted(Date.FormatStyle(locale: .german).day().month(.abbreviated)))
                            Button {
                                newContentDay = day
                                showingNewContent = true
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Content am \(day.formatted(date: .abbreviated, time: .omitted)) hinzufügen")
                        }
                    }
                    .contextMenu {
                        Button {
                            newContentDay = day
                            showingNewContent = true
                        } label: {
                            Label("Content hinzufügen", systemImage: "plus")
                        }
                    }
                }
            }
        }
        .navigationTitle("Woche")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewContent) {
            ContentEditorView(concert: nil, initialDate: newContentDay)
        }
    }

    private var weekRangeLabel: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let style = Date.FormatStyle(locale: .german)
        return "\(weekStart.formatted(style.day().month(.abbreviated))) – \(end.formatted(style.day().month(.abbreviated).year()))"
    }
}

extension Locale {
    /// Die App ist durchgängig auf Deutsch ausgelegt - unabhängig von der Geräte-Locale im Simulator/Test.
    static let german = Locale(identifier: "de_DE")
}
