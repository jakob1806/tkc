import SwiftUI
import SwiftData
import Charts

/// Erweiterung §9: Korrelation zwischen Content-Timing und Ticketverkauf.
/// Verkaufszahlen kommen nicht per API von der Konzertseite - sie werden manuell im
/// Konzert gepflegt (Concert.ticketsSold / venueCapacity), z.B. aus dem Ticketing-Partner-Report.
struct TicketCorrelationView: View {
    @Query(sort: \Concert.date) private var concerts: [Concert]

    private struct Row: Identifiable {
        let concert: Concert
        let contentCountBefore: Int
        var id: PersistentIdentifier { concert.id }
    }

    private var rows: [Row] {
        concerts.compactMap { concert in
            guard concert.occupancyRate != nil else { return nil }
            let cutoff = Calendar.current.date(byAdding: .day, value: -21, to: concert.date) ?? concert.date
            let count = concert.contentItems.filter { !$0.isUnplanned && $0.date >= cutoff && $0.date <= concert.date }.count
            return Row(concert: concert, contentCountBefore: count)
        }
    }

    var body: some View {
        List {
            if rows.isEmpty {
                ContentUnavailableView(
                    "Keine Verkaufsdaten",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Trage bei einem Konzert „Verkaufte Tickets“ und „Kapazität“ ein (Konzert-Detail), um die Korrelation zum Content-Timing zu sehen.")
                )
            } else {
                Section {
                    Chart(rows) { row in
                        PointMark(
                            x: .value("Content (21 Tage vorher)", row.contentCountBefore),
                            y: .value("Auslastung", row.concert.occupancyRate! * 100)
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(80)
                    }
                    .chartXAxisLabel("Content-Einträge vor dem Konzert")
                    .chartYAxisLabel("Auslastung %")
                    .frame(height: 240)
                } footer: {
                    Text("Jeder Punkt ist ein Konzert. Grober Anhaltspunkt, kein statistischer Beweis bei wenigen Konzerten.")
                }

                Section("Konzerte mit Verkaufsdaten") {
                    ForEach(rows.sorted(by: { $0.concert.date > $1.concert.date })) { row in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.concert.title).font(.subheadline.weight(.medium))
                            Text("\(Int((row.concert.occupancyRate ?? 0) * 100))% ausgelastet · \(row.contentCountBefore) Content-Einträge in den 21 Tagen davor")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Ticket-Korrelation")
    }
}
