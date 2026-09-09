import SwiftUI
import SwiftData

/// Chat-Oberfläche für den Chor Assistant (§KI-Konzept). Nutzt echte Gemini-Anbindung,
/// wenn ein API-Key in den Einstellungen hinterlegt ist.
struct ChorAssistantView: View {
    @Environment(\.modelContext) private var context
    @State private var messages: [GeminiAssistantService.ChatMessage] = []
    @State private var draft = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    private var settings = AppSettings.shared

    private static let suggestions = [
        "Was ist diese Woche noch nicht organisiert?",
        "Erstelle aus allen Konzerten im nächsten Monat einen Contentplan-Vorschlag.",
        "Welche Konzerte haben noch keinen geplanten Content?",
        "Fasse den Stand der aktuellen Projekte zusammen.",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if settings.geminiAPIKey.isEmpty {
                    ContentUnavailableView(
                        "Kein API-Key hinterlegt",
                        systemImage: "key.slash",
                        description: Text("Trage unter Einstellungen → Chor Assistant einen Gemini API-Key ein, um Fragen zu stellen.")
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                if messages.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Frag mich etwas über Konzerte, Content, Touren oder Besetzung.")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                        ForEach(Self.suggestions, id: \.self) { suggestion in
                                            Button(suggestion) { draft = suggestion }
                                                .font(.caption)
                                                .buttonStyle(.bordered)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                ForEach(messages) { message in
                                    ChatBubble(message: message).id(message.id)
                                }
                                if isLoading {
                                    ProgressView().padding(.horizontal)
                                }
                                if let errorMessage {
                                    Text(errorMessage).font(.caption).foregroundStyle(.red).padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        .onChange(of: messages.count) { _, _ in
                            if let last = messages.last { proxy.scrollTo(last.id) }
                        }
                    }

                    Divider()
                    HStack {
                        TextField("Frage stellen…", text: $draft, axis: .vertical)
                        Button {
                            Task { await send() }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill").font(.title2)
                        }
                        .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Chor Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func send() async {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        draft = ""
        errorMessage = nil
        messages.append(.init(role: .user, text: question))
        isLoading = true
        defer { isLoading = false }
        do {
            let answer = try await GeminiAssistantService.ask(question, history: messages.dropLast().map { $0 }, context: context)
            messages.append(.init(role: .model, text: answer))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ChatBubble: View {
    let message: GeminiAssistantService.ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .padding(10)
                .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)
            if message.role == .model { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}
