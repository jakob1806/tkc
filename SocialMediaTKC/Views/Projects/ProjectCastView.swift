import SwiftUI
import SwiftData

/// Besetzung eines Projekts: welche Sänger sind angefragt/bestätigt/abgesagt.
struct ProjectCastView: View {
    @Environment(\.modelContext) private var context
    @Bindable var project: Project
    @Query(sort: \Singer.name) private var allSingers: [Singer]
    @State private var showingAddSinger = false

    var body: some View {
        List {
            ForEach(VoicePart.allCases) { part in
                let assignments = project.castAssignments.filter { $0.singer?.voicePart == part }
                if !assignments.isEmpty {
                    Section(part.displayName) {
                        ForEach(assignments, id: \.persistentModelID) { assignment in
                            HStack {
                                Text(assignment.singer?.name ?? "?")
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { assignment.status },
                                    set: { assignment.status = $0 }
                                )) {
                                    ForEach(CastStatus.allCases) { status in
                                        Text(status.displayName).tag(status)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .onDelete { indices in
                            for index in indices { context.delete(assignments[index]) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Besetzung")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSinger = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddSinger) {
            AddSingerToProjectSheet(project: project, allSingers: allSingers)
        }
    }
}

private struct AddSingerToProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    let allSingers: [Singer]

    private var availableSingers: [Singer] {
        let assignedIDs = Set(project.castAssignments.compactMap { $0.singer?.persistentModelID })
        return allSingers.filter { !assignedIDs.contains($0.persistentModelID) && $0.isActive }
    }

    var body: some View {
        NavigationStack {
            List(availableSingers) { singer in
                Button {
                    let assignment = CastAssignment()
                    assignment.singer = singer
                    assignment.project = project
                    context.insert(assignment)
                    dismiss()
                } label: {
                    HStack {
                        Text(singer.name).foregroundStyle(.primary)
                        Spacer()
                        Text(singer.voicePart.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if availableSingers.isEmpty {
                    ContentUnavailableView("Keine Sänger verfügbar", systemImage: "person.3", description: Text("Lege Sänger unter „Chor“ an."))
                }
            }
            .navigationTitle("Sänger hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}
