import SwiftUI
import SwiftData
import Charts

/// §26 Followerentwicklung.
struct FollowerGrowthView: View {
    @Query private var accounts: [SocialAccount]
    @State private var platformFilter: SocialPlatform?
    @State private var days: Int = 30

    private var relevantAccounts: [SocialAccount] {
        platformFilter == nil ? accounts : accounts.filter { $0.platform == platformFilter }
    }

    private var cutoff: Date { Calendar.current.date(byAdding: .day, value: -days, to: .now)! }

    private var allSnapshots: [(SocialPlatform, FollowerSnapshot)] {
        relevantAccounts.flatMap { account in
            account.followerSnapshots.filter { $0.capturedAt >= cutoff }.map { (account.platform, $0) }
        }
    }

    private var currentTotal: Int { relevantAccounts.compactMap(\.followerCount).reduce(0, +) }

    private var growth: Int? {
        let earliest = allSnapshots.filter { $0.1.capturedAt <= cutoff.addingTimeInterval(86400) }
        guard !earliest.isEmpty else { return nil }
        let earliestTotal = earliest.reduce(0) { $0 + $1.1.followerCount }
        return currentTotal - earliestTotal
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Zeitraum", selection: $days) {
                        Text("30 Tage").tag(30)
                        Text("90 Tage").tag(90)
                        Text("1 Jahr").tag(365)
                    }
                    .pickerStyle(.segmented)

                    if allSnapshots.isEmpty {
                        Text("Noch keine Follower-Snapshots erfasst.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Chart(allSnapshots, id: \.1.persistentModelID) { platform, snapshot in
                            LineMark(x: .value("Datum", snapshot.capturedAt), y: .value("Follower", snapshot.followerCount))
                                .foregroundStyle(platform.color)
                        }
                        .frame(height: 220)
                    }

                    LabeledContent("Aktueller Stand", value: "\(currentTotal)")
                    if let growth {
                        LabeledContent("Zuwachs im Zeitraum", value: growth >= 0 ? "+\(growth)" : "\(growth)")
                    } else {
                        LabeledContent("Zuwachs im Zeitraum", value: "—")
                    }
                }

                Section("Plattform") {
                    Button("Alle") { platformFilter = nil }
                    ForEach(SocialPlatform.allCases) { platform in
                        Button(platform.displayName) { platformFilter = platform }
                    }
                }
            }
            .navigationTitle("Follower")
        }
    }
}
