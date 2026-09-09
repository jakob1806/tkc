import SwiftUI
import Charts

/// Zentrale Diagramm-Komponente (§7-§9): zeigt eine Linie je Kennzahl×Plattform-Kombination.
/// Unterstützt alle im Konzept geforderten Kombinationen:
/// - eine Kennzahl, alle Plattformen → vier Linien (eine je Plattform)
/// - eine Kennzahl, eine Plattform → eine Linie
/// - alle Kennzahlen, eine Plattform → mehrere Linien (eine je Kennzahl)
struct MainAnalyticsChart: View {
    let posts: [SocialPost]
    let range: ClosedRange<Date>
    let metricSelection: [SocialMetric]
    let platformSelection: [SocialPlatform]

    @State private var selectedDate: Date?

    private struct Line: Identifiable {
        let label: String
        let color: Color
        let points: [SocialAnalyticsRepository.SeriesPoint]
        var id: String { label }
    }

    /// Bei "alle Kennzahlen + eine Plattform" wird nach Kennzahl eingefärbt, ansonsten nach Plattform.
    private var lines: [Line] {
        if metricSelection.count > 1 {
            let platform = platformSelection.first ?? .instagram
            let platformPosts = posts.filter { $0.platform == platform }
            return metricSelection.map { metric in
                Line(
                    label: metric.displayName,
                    color: colorFor(metricIndex: metricSelection.firstIndex(of: metric) ?? 0),
                    points: SocialAnalyticsRepository.series(metric, posts: platformPosts, range: range)
                )
            }
        } else {
            let metric = metricSelection.first ?? .views
            return platformSelection.map { platform in
                let platformPosts = posts.filter { $0.platform == platform }
                return Line(
                    label: platform.displayName,
                    color: platform.color,
                    points: SocialAnalyticsRepository.series(metric, posts: platformPosts, range: range)
                )
            }
        }
    }

    private func colorFor(metricIndex: Int) -> Color {
        [Color.blue, .green, .orange, .purple, .pink][metricIndex % 5]
    }

    var body: some View {
        let allEmpty = lines.allSatisfy { $0.points.isEmpty }
        if allEmpty {
            ContentUnavailableView("Keine Daten im Zeitraum", systemImage: "chart.xyaxis.line")
        } else {
            Chart {
                ForEach(lines) { line in
                    ForEach(line.points) { point in
                        LineMark(x: .value("Datum", point.date), y: .value("Wert", point.value))
                            .foregroundStyle(by: .value("Serie", line.label))
                            .interpolationMethod(.catmullRom)
                    }
                    .foregroundStyle(line.color)
                }

                if let selectedDate {
                    RuleMark(x: .value("Ausgewählt", selectedDate))
                        .foregroundStyle(.secondary.opacity(0.3))
                }
            }
            .chartLegend(position: .bottom, spacing: 8)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let originX = geo[proxy.plotAreaFrame].origin.x
                                    guard let date: Date = proxy.value(atX: value.location.x - originX) else { return }
                                    selectedDate = date
                                }
                                .onEnded { _ in selectedDate = nil }
                        )
                }
            }
            .overlay(alignment: .topLeading) {
                if let selectedDate, let tooltip = tooltipText(for: selectedDate) {
                    Text(tooltip)
                        .font(.caption)
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(6)
                }
            }
        }
    }

    private func tooltipText(for date: Date) -> String? {
        let calendar = Calendar.current
        var text = date.formatted(date: .abbreviated, time: .omitted)
        var found = false
        for line in lines {
            if let point = line.points.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                text += "\n\(line.label): \(point.value.formatted())"
                found = true
            }
        }
        return found ? text : nil
    }
}
