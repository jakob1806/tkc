import SwiftUI
import SwiftData

struct SocialAccountDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var account: SocialAccount
    @State private var showingNewPost = false

    var body: some View {
        List {
            Section {
                TextField("Anzeigename", text: $account.displayName)
                TextField("Benutzername", text: $account.username)
                HStack {
                    Text("Follower")
                    Spacer()
                    TextField("–", text: Binding(
                        get: { account.followerCount.map(String.init) ?? "" },
                        set: { account.followerCount = Int($0) }
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                }
                if let lastSync = account.lastSyncedAt {
                    LabeledContent("Zuletzt synchronisiert", value: lastSync.formatted(.relative(presentation: .named)))
                }
                if let error = account.lastSyncError {
                    Label(error.displayName, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
            }

            Section("Posts (\(account.posts.count))") {
                ForEach(account.posts.sorted(by: { $0.publishedAt > $1.publishedAt })) { post in
                    NavigationLink {
                        SocialPostDetailView(post: post)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.caption ?? post.postType.displayName)
                            HStack {
                                Text(post.postType.displayName)
                                Text(post.publishedAt.formatted(date: .abbreviated, time: .omitted))
                                if let views = post.latestSnapshot?.views {
                                    Text("\(views) Views")
                                } else {
                                    Text("Views —")
                                }
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indices in
                    let sorted = account.posts.sorted(by: { $0.publishedAt > $1.publishedAt })
                    for index in indices { context.delete(sorted[index]) }
                }
                Button {
                    showingNewPost = true
                } label: {
                    Label("Post erfassen", systemImage: "plus")
                }
            }
        }
        .navigationTitle(account.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewPost) {
            NewSocialPostSheet(account: account)
        }
    }
}

private struct NewSocialPostSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var account: SocialAccount

    @State private var postType: SocialPostType
    @State private var caption = ""
    @State private var publishedAt = Date.now
    @State private var views = ""
    @State private var likes = ""
    @State private var comments = ""
    @State private var shares = ""

    init(account: SocialAccount) {
        self.account = account
        _postType = State(initialValue: SocialPostType.availableTypes(for: account.platform).first ?? .feedPost)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Typ", selection: $postType) {
                    ForEach(SocialPostType.availableTypes(for: account.platform)) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                TextField("Caption/Titel", text: $caption, axis: .vertical)
                DatePicker("Veröffentlicht", selection: $publishedAt)

                Section {
                    metricField("Views", text: $views)
                    metricField("Likes", text: $likes)
                    metricField("Kommentare", text: $comments)
                    metricField("Shares", text: $shares)
                } header: {
                    Text("Erster Snapshot")
                } footer: {
                    Text("Leer lassen, wenn eine Kennzahl nicht bekannt ist - wird dann als „nicht verfügbar“ angezeigt, nie als 0.")
                }
            }
            .navigationTitle("Neuer Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let post = SocialPost(
                            externalPostId: UUID().uuidString,
                            postType: postType,
                            caption: caption.isEmpty ? nil : caption,
                            publishedAt: publishedAt
                        )
                        post.account = account
                        context.insert(post)
                        let snapshot = SocialMetricSnapshot(
                            views: Int(views), likes: Int(likes), comments: Int(comments), shares: Int(shares)
                        )
                        snapshot.post = post
                        context.insert(snapshot)
                        dismiss()
                    }
                    .disabled(caption.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func metricField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("–", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }
}
