import SwiftUI

/// Verbindet Monats- (§2) und Wochenansicht (§19) über einen Segmented Control.
struct CalendarContainerView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case month = "Monat", week = "Woche"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .month

    var body: some View {
        VStack(spacing: 0) {
            Picker("Ansicht", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            switch mode {
            case .month: CalendarMonthView()
            case .week: NavigationStack { CalendarWeekView() }
            }
        }
    }
}
