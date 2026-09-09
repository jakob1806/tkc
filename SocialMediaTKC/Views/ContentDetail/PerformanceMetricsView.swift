import SwiftUI

/// §24 Optional: Performance-Kennzahlen manuell eintragen (spätere Ausbaustufe: API-Import).
struct PerformanceMetricsView: View {
    @Bindable var item: ContentItem

    var body: some View {
        metricField("Views", value: Binding(
            get: { item.metricViews }, set: { item.metricViews = $0 }
        ))
        metricField("Likes", value: Binding(
            get: { item.metricLikes }, set: { item.metricLikes = $0 }
        ))
        metricField("Kommentare", value: Binding(
            get: { item.metricComments }, set: { item.metricComments = $0 }
        ))
        metricField("Shares", value: Binding(
            get: { item.metricShares }, set: { item.metricShares = $0 }
        ))
        metricField("Saves", value: Binding(
            get: { item.metricSaves }, set: { item.metricSaves = $0 }
        ))
        metricField("Reichweite", value: Binding(
            get: { item.metricReach }, set: { item.metricReach = $0 }
        ))
        metricField("Follower-Wachstum", value: Binding(
            get: { item.metricFollowerGrowth }, set: { item.metricFollowerGrowth = $0 }
        ))
    }

    private func metricField(_ title: String, value: Binding<Int?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("–", text: Binding(
                get: { value.wrappedValue.map(String.init) ?? "" },
                set: { value.wrappedValue = Int($0) }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 80)
        }
    }
}
