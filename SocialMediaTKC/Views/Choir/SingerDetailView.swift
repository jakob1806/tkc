import SwiftUI
import SwiftData

struct SingerDetailView: View {
    @Bindable var singer: Singer

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $singer.name)
                Picker("Stimmgruppe", selection: $singer.voicePart) {
                    ForEach(VoicePart.allCases) { part in
                        Text(part.displayName).tag(part)
                    }
                }
                Toggle("Aktiv", isOn: $singer.isActive)
                TextField("Kontakt", text: Binding(get: { singer.contact ?? "" }, set: { singer.contact = $0.isEmpty ? nil : $0 }))
                TextField("Notizen", text: Binding(get: { singer.notes ?? "" }, set: { singer.notes = $0.isEmpty ? nil : $0 }), axis: .vertical)
            }

            Section("Projekteinsätze") {
                if singer.assignments.isEmpty {
                    Text("Noch keine Einsätze.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(singer.assignments, id: \.persistentModelID) { assignment in
                    HStack {
                        Text(assignment.project?.title ?? "?")
                        Spacer()
                        Text(assignment.status.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(singer.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
