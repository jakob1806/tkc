import SwiftUI
import SwiftData

/// "Chor"-Tab: Sänger, Stimmgruppen, Projekteinsätze (Chor & Besetzung im neuen Konzept).
struct ChoirRosterView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Singer.name) private var singers: [Singer]
    @State private var showingNewSinger = false
    @State private var searchText = ""

    private var filtered: [Singer] {
        searchText.isEmpty ? singers : singers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(VoicePart.allCases) { part in
                    let group = filtered.filter { $0.voicePart == part }
                    if !group.isEmpty {
                        Section("\(part.displayName) (\(group.count))") {
                            ForEach(group) { singer in
                                NavigationLink {
                                    SingerDetailView(singer: singer)
                                } label: {
                                    HStack {
                                        Text(singer.name)
                                        if !singer.isActive {
                                            Text("inaktiv").font(.caption2).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(singer.assignments.count) Projekte").font(.caption2).foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .overlay {
                if singers.isEmpty {
                    ContentUnavailableView("Kein Chor angelegt", systemImage: "person.3", description: Text("Lege Sänger mit Stimmgruppe an, um Besetzungen zu planen."))
                }
            }
            .searchable(text: $searchText, prompt: "Name…")
            .navigationTitle("Chor")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewSinger = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNewSinger) {
                NewSingerSheet()
            }
        }
    }
}

private struct NewSingerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var voicePart: VoicePart = .sopranoI
    @State private var contact = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Stimmgruppe", selection: $voicePart) {
                    ForEach(VoicePart.allCases) { part in
                        Text(part.displayName).tag(part)
                    }
                }
                TextField("Kontakt (E-Mail/Telefon)", text: $contact)
            }
            .navigationTitle("Neuer Sänger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let singer = Singer(name: name, voicePart: voicePart, contact: contact.isEmpty ? nil : contact)
                        context.insert(singer)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
