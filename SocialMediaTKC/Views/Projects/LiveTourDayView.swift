import SwiftUI

/// Live-Tourmodus (§Konzept): stark vereinfachte Ansicht während der Reise -
/// nur "was jetzt zählt", statt der vollen Planungsoberfläche.
struct LiveTourDayView: View {
    let day: TourDay

    private var nextEvent: TourEvent? {
        day.sortedEvents.first { $0.time > .now }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(day.cityOrLocation).font(.largeTitle.bold())
                    Text(day.date.formatted(date: .complete, time: .omitted)).foregroundStyle(.secondary)
                }
                .padding(.top, 24)

                if let nextEvent {
                    VStack(spacing: 8) {
                        Label("Nächster Termin", systemImage: nextEvent.type.symbol)
                            .font(.caption).foregroundStyle(.secondary)
                        Text(nextEvent.title).font(.title2.weight(.semibold))
                        Text(nextEvent.time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                        if let location = nextEvent.location {
                            Text(location).foregroundStyle(.secondary)
                        }
                        if let busInfo = nextEvent.busOrSeatInfo {
                            Text(busInfo).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                }

                if let hotel = day.hotelName {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(hotel, systemImage: "bed.double.fill")
                        if let address = day.hotelAddress {
                            Text(address).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Ganzer Tag").font(.headline).padding(.horizontal)
                    ForEach(day.sortedEvents) { event in
                        HStack {
                            Text(event.time.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline.monospacedDigit())
                                .frame(width: 56, alignment: .leading)
                            Image(systemName: event.type.symbol)
                            Text(event.title)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .foregroundStyle(event.time > .now ? .primary : .secondary)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle("Heute")
        .navigationBarTitleDisplayMode(.inline)
    }
}
