import SwiftUI
import SwiftData

/// §13 Aufgaben mit Fortschrittsanzeige.
struct TaskChecklistView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: ContentItem
    @State private var newTaskTitle = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !item.tasks.isEmpty {
                ProgressView(value: item.taskProgress)
                    .tint(item.taskProgress == 1 ? .green : .accentColor)
            }
            ForEach(item.tasks.sorted(by: { $0.createdAt < $1.createdAt })) { task in
                Button {
                    task.completed.toggle()
                } label: {
                    Label(task.title, systemImage: task.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.completed ? .secondary : .primary)
                        .strikethrough(task.completed)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button(role: .destructive) {
                        context.delete(task)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
            HStack {
                TextField("Neue Aufgabe", text: $newTaskTitle)
                Button("Hinzufügen") {
                    guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let task = ContentTask(title: newTaskTitle)
                    task.contentItem = item
                    context.insert(task)
                    newTaskTitle = ""
                }
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
