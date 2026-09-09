import SwiftUI
import SwiftData

/// Tourplanung: Reisetage mit Tagesplan (§Tourplanung-Konzept), inkl. vereinfachter
/// "Live-Tourmodus"-Kachel für den aktuellen Tag.
struct TourDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var tour: Tour
    @State private var showingNewDay = false

    private var today: TourDay? {
        tour.days.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        List {
            if let today {
                Section {
                    NavigationLink {
                        LiveTourDayView(day: today)
                    } label: {
                        LiveTourTile(day: today)
                    }
                }
            }

            Section("Reisetage") {
                ForEach(tour.sortedDays) { day in
                    NavigationLink {
                        TourDayDetailView(day: day)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.date.formatted(date: .complete, time: .omitted)).font(.subheadline.weight(.medium))
                            Text(day.cityOrLocation).font(.caption).foregroundStyle(.secondary)
                            if !day.events.isEmpty {
                                Text("\(day.events.count) Programmpunkte").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .onDelete { indices in
                    for index in indices { context.delete(tour.sortedDays[index]) }
                }
                Button {
                    showingNewDay = true
                } label: {
                    Label("Reisetag hinzufügen", systemImage: "plus")
                }
            }
        }
        .navigationTitle(tour.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewDay) {
            NewTourDaySheet(tour: tour)
        }
    }
}

private struct LiveTourTile: View {
    let day: TourDay

    private var nextEvent: TourEvent? {
        day.sortedEvents.first { $0.time > .now }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Heute · \(day.cityOrLocation)").font(.headline)
            if let nextEvent {
                Text("Nächster Termin: \(nextEvent.title) · \(nextEvent.time.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                if let busInfo = nextEvent.busOrSeatInfo {
                    Text(busInfo).font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("Keine weiteren Programmpunkte heute").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct NewTourDaySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var tour: Tour

    @State private var date = Date.now
    @State private var city = ""
    @State private var hotelName = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Datum", selection: $date, displayedComponents: .date)
                TextField("Ort/Stadt", text: $city)
                TextField("Hotel", text: $hotelName)
            }
            .navigationTitle("Neuer Reisetag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let day = TourDay(date: date, cityOrLocation: city, hotelName: hotelName.isEmpty ? nil : hotelName)
                        day.tour = tour
                        context.insert(day)
                        dismiss()
                    }
                    .disabled(city.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
