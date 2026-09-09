import SwiftUI
import SwiftData

/// Medien-Hub: zentrale Übersicht über alle Fotos/Videos/Grafiken/Audio aus allen
/// Content-Einträgen, mit Rechte-/Lizenzinfo statt verstreut in einzelnen Beiträgen.
struct MediaLibraryView: View {
    @Query private var assets: [Asset]
    @State private var searchText = ""
    @State private var filterType: AssetType?

    private var filtered: [Asset] {
        assets
            .filter { filterType == nil || $0.type == filterType }
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "Keine Medien",
                        systemImage: "photo.stack",
                        description: Text("Fotos/Videos werden über Content-Einträge (Assets) importiert und erscheinen hier automatisch.")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filtered) { asset in
                            NavigationLink {
                                MediaDetailView(asset: asset)
                            } label: {
                                MediaThumbnail(asset: asset)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Medien")
            .searchable(text: $searchText, prompt: "Titel…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Alle") { filterType = nil }
                        ForEach(AssetType.allCases) { type in
                            Button(type.displayName) { filterType = type }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

private struct MediaThumbnail: View {
    let asset: Asset

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground))
                if let data = asset.mediaData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: asset.type.symbol).font(.title).foregroundStyle(.secondary)
                }
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(asset.title).font(.caption2).lineLimit(1)
        }
    }
}

private struct MediaDetailView: View {
    @Bindable var asset: Asset

    var body: some View {
        Form {
            Section {
                if let data = asset.mediaData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 260)
                        .frame(maxWidth: .infinity)
                }
            }
            Section {
                TextField("Titel", text: $asset.title)
                LabeledContent("Typ", value: asset.type.displayName)
                if let contentItem = asset.contentItem {
                    LabeledContent("Verwendet in", value: contentItem.title)
                }
                if let externalURL = asset.externalURL {
                    Link(externalURL, destination: URL(string: externalURL) ?? URL(string: "https://")!)
                }
            }
            Section("Rechte & Lizenz") {
                TextField("Rechteinhaber/Fotograf", text: Binding(get: { asset.rightsHolder ?? "" }, set: { asset.rightsHolder = $0.isEmpty ? nil : $0 }))
                TextField("Lizenzhinweis / Nutzungsbeschränkung", text: Binding(get: { asset.licenseNote ?? "" }, set: { asset.licenseNote = $0.isEmpty ? nil : $0 }), axis: .vertical)
            }
        }
        .navigationTitle(asset.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
