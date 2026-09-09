import SwiftUI
import SwiftData

/// §6 Assets: Fotos, Videos, Grafiken, Canva/Drive-Links, Audio, Dokumente.
struct AssetListView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: ContentItem
    @State private var showingAddAsset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(item.assets.sorted(by: { $0.createdAt < $1.createdAt })) { asset in
                Label(asset.title, systemImage: asset.type.symbol)
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(asset)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
            }
            Button {
                showingAddAsset = true
            } label: {
                Label("Asset hinzufügen", systemImage: "paperclip")
            }
        }
        .sheet(isPresented: $showingAddAsset) {
            AddAssetSheet(item: item)
        }
    }
}

private struct AddAssetSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ContentItem

    @State private var type: AssetType = .photo
    @State private var title = ""
    @State private var externalURL = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Typ", selection: $type) {
                    ForEach(AssetType.allCases) { type in
                        Label(type.displayName, systemImage: type.symbol).tag(type)
                    }
                }
                TextField("Titel", text: $title)
                TextField("Link (Canva, Drive, Dropbox, …)", text: $externalURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .navigationTitle("Neues Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        let asset = Asset(type: type, title: title.isEmpty ? type.displayName : title, externalURL: externalURL.isEmpty ? nil : externalURL)
                        asset.contentItem = item
                        context.insert(asset)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
