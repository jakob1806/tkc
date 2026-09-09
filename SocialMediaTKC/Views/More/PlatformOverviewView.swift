import SwiftUI
import SwiftData

/// §22 Plattformübersicht: erkennt schnell, wenn eine Plattform kaum bespielt wird.
struct PlatformOverviewView: View {
    @Query private var allItems: [ContentItem]

    private var counts: [(Platform, Int)] {
        Platform.allCases.map { platform in
            (platform, allItems.filter { $0.platform == platform && !$0.isUnplanned }.count)
        }
    }

    private var maxCount: Int { max(counts.map(\.1).max() ?? 1, 1) }

    var body: some View {
        List {
            Section {
                ForEach(counts, id: \.0) { platform, count in
                    HStack {
                        Label(platform.displayName, systemImage: platform.symbol)
                            .foregroundStyle(platform.color)
                        Spacer()
                        Text("\(count) geplant")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(platform.color.opacity(0.25))
                            .frame(width: geo.size.width, height: 6)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(platform.color)
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount), height: 6)
                            }
                    }
                    .frame(height: 6)
                    .padding(.bottom, 4)
                }
            } footer: {
                Text("Zeigt geplante Content-Einträge je Plattform (ohne Ideen ohne Datum).")
            }
        }
        .navigationTitle("Plattformübersicht")
    }
}
