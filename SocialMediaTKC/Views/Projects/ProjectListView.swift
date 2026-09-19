import SwiftUI
import SwiftData

/// "Projekte" bündelt Produktionen/Tourneen (das verbindende Element im Choir-Operations-Konzept)
/// und darunter die flache Konzertliste für alles, was noch keinem Projekt zugeordnet ist.
struct ProjectListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Query(sort: \Concert.date) private var concerts: [Concert]
    @State private var showingNewProject = false
    @State private var projectToDelete: Project?

    private var unassignedConcerts: [Concert] {
        concerts.filter { $0.project == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Projekte") {
                    if projects.isEmpty {
                        Text("Noch keine Projekte angelegt.").foregroundStyle(.secondary)
                    }
                    ForEach(projects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectRow(project: project)
                        }
                    }
                    .onDelete { indices in
                        projectToDelete = indices.first.map { projects[$0] }
                    }
                }

                Section("Konzerte ohne Projekt") {
                    if unassignedConcerts.isEmpty {
                        Text("Alle Konzerte sind einem Projekt zugeordnet.").font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(unassignedConcerts) { concert in
                        NavigationLink {
                            ConcertDetailView(concert: concert)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(concert.title)
                                Text("\(concert.date.formatted(date: .abbreviated, time: .omitted)) · \(concert.venue)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Projekte")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewProject = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectSheet()
            }
            .confirmationDialog(
                "Projekt „\(projectToDelete?.title ?? "")“ löschen?",
                isPresented: Binding(get: { projectToDelete != nil }, set: { if !$0 { projectToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Projekt inkl. Tour und Besetzung löschen", role: .destructive) {
                    if let project = projectToDelete { context.delete(project) }
                    projectToDelete = nil
                }
            } message: {
                Text("Tour, Reisetage und Besetzung werden mitgelöscht. Zugeordnete Konzerte bleiben erhalten.")
            }
        }
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack {
            Image(systemName: project.kind.symbol)
                .frame(width: 28)
                .foregroundStyle(.indigo)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title).font(.headline)
                HStack(spacing: 6) {
                    Text(project.kind.displayName)
                    if let range = project.dateRangeLabel {
                        Text("· \(range)")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Label("\(project.concerts.count)", systemImage: "music.mic").font(.caption2)
                    Label("\(project.contentItemCount)", systemImage: "square.grid.2x2").font(.caption2)
                    if project.tour != nil {
                        Label("\(project.tour?.days.count ?? 0) Tage", systemImage: "bus").font(.caption2)
                    }
                }
                .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct NewProjectSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Concert.date) private var allConcerts: [Concert]

    @State private var title = ""
    @State private var kind: ProjectKind = .production
    @State private var selectedConcertIDs: Set<PersistentIdentifier> = []

    var body: some View {
        NavigationStack {
            Form {
                TextField("Titel (z.B. „Die Zauberflöte – Zürich“)", text: $title)
                Picker("Art", selection: $kind) {
                    ForEach(ProjectKind.allCases) { kind in
                        Label(kind.displayName, systemImage: kind.symbol).tag(kind)
                    }
                }
                Section("Konzerte zuordnen") {
                    ForEach(allConcerts.filter { $0.project == nil }) { concert in
                        Button {
                            if selectedConcertIDs.contains(concert.persistentModelID) {
                                selectedConcertIDs.remove(concert.persistentModelID)
                            } else {
                                selectedConcertIDs.insert(concert.persistentModelID)
                            }
                        } label: {
                            HStack {
                                Text(concert.title).foregroundStyle(.primary)
                                Spacer()
                                if selectedConcertIDs.contains(concert.persistentModelID) {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Neues Projekt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        let project = Project(title: title, kind: kind)
                        context.insert(project)
                        if kind == .tour {
                            let tour = Tour(title: title)
                            tour.project = project
                            project.tour = tour
                            context.insert(tour)
                        }
                        for concert in allConcerts where selectedConcertIDs.contains(concert.persistentModelID) {
                            concert.project = project
                        }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
