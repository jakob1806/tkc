import SwiftUI
import SwiftData
import PhotosUI

/// §6 Assets: Fotos, Videos, Grafiken, Canva/Drive-Links, Audio, Dokumente.
struct AssetListView: View {
    @Environment(\.modelContext) private var context
    @Bindable var item: ContentItem
    @State private var showingAddAsset = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isImportingPhoto = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(item.assets.sorted(by: { $0.createdAt < $1.createdAt })) { asset in
                HStack {
                    if let data = asset.mediaData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: asset.type.symbol)
                            .frame(width: 32, height: 32)
                    }
                    Text(asset.title)
                    if asset.hasEmbeddedMedia {
                        Spacer()
                        Text("importiert").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        context.delete(asset)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }

            PhotosPicker(selection: $photosPickerItem, matching: .any(of: [.images, .videos])) {
                Label(isImportingPhoto ? "Importiere…" : "Foto/Video aus Mediathek", systemImage: "photo.on.rectangle.angled")
            }
            .disabled(isImportingPhoto)
            .onChange(of: photosPickerItem) { _, newValue in
                guard let newValue else { return }
                Task { await importPhoto(newValue) }
            }

            Button {
                showingAddAsset = true
            } label: {
                Label("Link-Asset hinzufügen", systemImage: "paperclip")
            }
        }
        .sheet(isPresented: $showingAddAsset) {
            AddAssetSheet(item: item)
        }
    }

    private func importPhoto(_ pickerItem: PhotosPickerItem) async {
        isImportingPhoto = true
        defer { isImportingPhoto = false }
        guard let data = try? await pickerItem.loadTransferable(type: Data.self) else { return }
        let isVideo = pickerItem.supportedContentTypes.contains { $0.conforms(to: .movie) }
        let asset = Asset(
            type: isVideo ? .video : .photo,
            title: isVideo ? "Video (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))" : "Foto (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))",
            mediaData: data,
            mediaFilenameExtension: isVideo ? "mov" : "jpg"
        )
        asset.contentItem = item
        context.insert(asset)
        photosPickerItem = nil
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
