import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// §18 Export: Zeitraum wählen, Felder wählen, als PDF/CSV/Text exportieren oder kopieren.
struct ExportView: View {
    @Query(sort: \ContentItem.date) private var allItems: [ContentItem]

    @State private var startDate: Date = Calendar.current.startOfMonth(for: .now)
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Calendar.current.startOfMonth(for: .now))!
    @State private var selectedFields: Set<ExportField> = [.platform, .contentType, .status, .publishTime]
    @State private var copiedConfirmation = false
    @State private var pdfURL: IdentifiableURL?
    @State private var csvURL: IdentifiableURL?

    private var itemsInRange: [ContentItem] {
        allItems.filter { !$0.isUnplanned && $0.date >= startDate && $0.date <= endDate }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Zeitraum") {
                    DatePicker("Von", selection: $startDate, displayedComponents: .date)
                    DatePicker("Bis", selection: $endDate, displayedComponents: .date)
                    Text("\(itemsInRange.count) Content-Einträge im Zeitraum")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Felder") {
                    ForEach(ExportField.allCases) { field in
                        Toggle(field.displayName, isOn: Binding(
                            get: { selectedFields.contains(field) },
                            set: { isOn in
                                if isOn { selectedFields.insert(field) } else { selectedFields.remove(field) }
                            }
                        ))
                    }
                }

                Section("Contentplan exportieren") {
                    Button {
                        UIPasteboard.general.string = ExportService.plainText(items: itemsInRange, fields: selectedFields)
                        copiedConfirmation = true
                    } label: {
                        Label("In Zwischenablage kopieren", systemImage: "doc.on.doc")
                    }

                    Button {
                        pdfURL = writeTempFile(
                            data: ExportService.pdf(items: itemsInRange, fields: selectedFields, title: "TKC Contentplan"),
                            filename: "Contentplan.pdf"
                        )
                    } label: {
                        Label("Als PDF exportieren", systemImage: "doc.richtext")
                    }

                    Button {
                        let csv = ExportService.csv(items: itemsInRange, fields: selectedFields)
                        csvURL = writeTempFile(data: Data(csv.utf8), filename: "Contentplan.csv")
                    } label: {
                        Label("Als CSV/Excel exportieren", systemImage: "tablecells")
                    }

                    ShareLink(item: ExportService.plainText(items: itemsInRange, fields: selectedFields)) {
                        Label("Share Sheet (Text)", systemImage: "square.and.arrow.up")
                    }
                }

                if !itemsInRange.isEmpty {
                    Section("Vorschau") {
                        Text(ExportService.plainText(items: itemsInRange, fields: selectedFields))
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Export")
            .alert("In Zwischenablage kopiert", isPresented: $copiedConfirmation) {
                Button("OK", role: .cancel) {}
            }
            .sheet(item: $pdfURL) { boxed in
                ShareSheet(activityItems: [boxed.url])
            }
            .sheet(item: $csvURL) { boxed in
                ShareSheet(activityItems: [boxed.url])
            }
        }
    }

    private func writeTempFile(data: Data, filename: String) -> IdentifiableURL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return IdentifiableURL(url: url)
        } catch {
            return nil
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.path }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
