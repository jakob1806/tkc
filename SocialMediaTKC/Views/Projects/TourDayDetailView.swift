import SwiftUI
import SwiftData

/// Der Tagesplan eines Reisetags - Kernstück der Tourplanung im neuen Konzept.
struct TourDayDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var day: TourDay
    @State private var showingNewEvent = false

    var body: some View {
        List {
            Section("Unterkunft") {
                TextField("Hotel", text: Binding(get: { day.hotelName ?? "" }, set: { day.hotelName = $0.isEmpty ? nil : $0 }))
                TextField("Adresse", text: Binding(get: { day.hotelAddress ?? "" }, set: { day.hotelAddress = $0.isEmpty ? nil : $0 }))
            }

            Section("Tagesplan") {
                ForEach(day.sortedEvents) { event in
                    HStack(alignment: .top) {
                        Text(event.time.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 56, alignment: .leading)
                        Image(systemName: event.type.symbol).foregroundStyle(.indigo)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                            if let location = event.location, !location.isEmpty {
                                Text(location).font(.caption).foregroundStyle(.secondary)
                            }
                            if let busInfo = event.busOrSeatInfo, !busInfo.isEmpty {
                                Text(busInfo).font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .onDelete { indices in
                    for index in indices { context.delete(day.sortedEvents[index]) }
                }
                Button {
                    showingNewEvent = true
                } label: {
                    Label("Programmpunkt hinzufügen", systemImage: "plus")
                }
            }

            Section("Notizen") {
                TextField("Notizen", text: Binding(get: { day.notes ?? "" }, set: { day.notes = $0.isEmpty ? nil : $0 }), axis: .vertical)
            }
        }
        .navigationTitle(day.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewEvent) {
            NewTourEventSheet(day: day)
        }
    }
}

private struct NewTourEventSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var day: TourDay

    @State private var time = Date.now
    @State private var title = ""
    @State private var type: TourEventType = .transfer
    @State private var location = ""
    @State private var busInfo = ""

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Uhrzeit", selection: $time, displayedComponents: .hourAndMinute)
                TextField("Titel (z.B. „Bus zum Bahnhof“)", text: $title)
                Picker("Typ", selection: $type) {
                    ForEach(TourEventType.allCases) { type in
                        Label(type.displayName, systemImage: type.symbol).tag(type)
                    }
                }
                TextField("Ort", text: $location)
                TextField("Bus/Sitzplatz (optional)", text: $busInfo)
            }
            .navigationTitle("Neuer Programmpunkt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let combined = Calendar.current.date(
                            bySettingHour: Calendar.current.component(.hour, from: time),
                            minute: Calendar.current.component(.minute, from: time),
                            second: 0,
                            of: day.date
                        ) ?? day.date
                        let event = TourEvent(time: combined, title: title, type: type, location: location.isEmpty ? nil : location, busOrSeatInfo: busInfo.isEmpty ? nil : busInfo)
                        event.tourDay = day
                        context.insert(event)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
