import SwiftUI
import SwiftData

/// Kommentar-Thread an einem Content-Item (Erweiterung zu §14 Freigabeprozess) - für das
/// Hin-und-Her zwischen Redaktion und Freigebenden, statt nur einem einzelnen Kommentarfeld.
struct CommentThreadView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: ContentItem
    @State private var newComment = ""
    var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(item.comments.sorted(by: { $0.createdAt < $1.createdAt })) { comment in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(comment.author).font(.caption.weight(.semibold))
                        Spacer()
                        Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundStyle(.tertiary)
                    }
                    Text(comment.text).font(.subheadline)
                }
                .padding(.vertical, 2)
                .swipeActions {
                    Button(role: .destructive) { context.delete(comment) } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
            if item.comments.isEmpty {
                Text("Noch keine Kommentare.").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                TextField("Kommentar schreiben…", text: $newComment, axis: .vertical)
                Button {
                    let author = settings.displayName.isEmpty ? "Unbekannt" : settings.displayName
                    let comment = Comment(author: author, text: newComment)
                    comment.contentItem = item
                    context.insert(comment)
                    newComment = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                }
                .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
