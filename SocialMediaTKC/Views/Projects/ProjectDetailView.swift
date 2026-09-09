import SwiftUI
import SwiftData

/// Projekt-Detail: Übersicht · Konzerte · Besetzung · Reise · Content - der "Bindeglied"-Gedanke
/// des Choir-Operations-Konzepts an einer Stelle sichtbar gemacht.
struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var project: Project
    @Query(sort: \Concert.date) private var allConcerts: [Concert]
    @Query private var allSocialPosts: [SocialPost]
    @State private var showingAddConcert = false

    /// §18 Projekt-Analytics: alle Social Posts, die entweder direkt oder über ein Konzert
    /// dieses Projekts verknüpft sind.
    private var linkedSocialPosts: [SocialPost] {
        allSocialPosts.filter {
            $0.linkedProject?.persistentModelID == project.persistentModelID ||
            ($0.linkedConcert != nil && $0.linkedConcert?.project?.persistentModelID == project.persistentModelID)
        }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Art", value: project.kind.displayName)
                if let range = project.dateRangeLabel {
                    LabeledContent("Zeitraum", value: range)
                }
                TextField("Notizen", text: Binding(
                    get: { project.notes ?? "" },
                    set: { project.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
            }

            Section("Konzerte (\(project.concerts.count))") {
                ForEach(project.sortedConcerts) { concert in
                    NavigationLink {
                        ConcertDetailView(concert: concert)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(concert.title)
                            Text("\(concert.date.formatted(date: .abbreviated, time: .omitted)) · \(concert.venue), \(concert.city)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Button {
                    showingAddConcert = true
                } label: {
                    Label("Konzert hinzufügen", systemImage: "plus")
                }
            }

            if let tour = project.tour {
                Section("Reise") {
                    NavigationLink {
                        TourDetailView(tour: tour)
                    } label: {
                        Label("\(tour.days.count) Reisetage", systemImage: "bus")
                    }
                }
            } else if project.kind == .tour {
                Section {
                    Button {
                        let tour = Tour(title: project.title)
                        tour.project = project
                        project.tour = tour
                        context.insert(tour)
                    } label: {
                        Label("Reiseplan anlegen", systemImage: "bus")
                    }
                }
            }

            Section("Besetzung (\(project.castAssignments.count))") {
                NavigationLink {
                    ProjectCastView(project: project)
                } label: {
                    Label("Besetzung verwalten", systemImage: "person.3")
                }
            }

            Section("Content (\(project.contentItemCount))") {
                ForEach(project.concerts.flatMap(\.contentItems).sorted(by: { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) }).prefix(10)) { item in
                    NavigationLink {
                        ContentDetailView(item: item)
                    } label: {
                        Text(item.title)
                    }
                }
            }

            if !linkedSocialPosts.isEmpty {
                Section("Social Performance") {
                    ForEach(SocialPlatform.allCases) { platform in
                        let posts = linkedSocialPosts.filter { $0.platform == platform }
                        if !posts.isEmpty {
                            let views = posts.compactMap { $0.latestSnapshot?.views }.reduce(0, +)
                            LabeledContent {
                                Text("\(views.formatted()) Views")
                            } label: {
                                Label(platform.displayName, systemImage: platform.symbol).foregroundStyle(platform.color)
                            }
                        }
                    }
                    let totalViews = linkedSocialPosts.compactMap { $0.latestSnapshot?.views }.reduce(0, +)
                    LabeledContent("Gesamt", value: "\(totalViews.formatted()) Views · \(linkedSocialPosts.count) Posts")
                }
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddConcert) {
            AddConcertToProjectSheet(project: project, availableConcerts: allConcerts.filter { $0.project == nil })
        }
    }
}

private struct AddConcertToProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var project: Project
    let availableConcerts: [Concert]

    var body: some View {
        NavigationStack {
            List(availableConcerts) { concert in
                Button {
                    concert.project = project
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(concert.title).foregroundStyle(.primary)
                        Text(concert.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if availableConcerts.isEmpty {
                    ContentUnavailableView("Keine freien Konzerte", systemImage: "music.mic")
                }
            }
            .navigationTitle("Konzert hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}
