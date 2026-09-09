import SwiftUI
import SwiftData

/// §12 Content Performance: alle Posts sortier- und filterbar.
struct ContentPerformanceView: View {
    @Query private var allPosts: [SocialPost]

    private enum SortOption: String, CaseIterable, Identifiable {
        case views, likes, comments, shares, engagement, newest, oldest
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .views: return "Höchste Views"
            case .likes: return "Höchste Likes"
            case .comments: return "Höchste Kommentare"
            case .shares: return "Höchste Shares"
            case .engagement: return "Höchste Engagement Rate"
            case .newest: return "Neueste"
            case .oldest: return "Älteste"
            }
        }
    }

    @State private var sortOption: SortOption = .views
    @State private var platformFilter: SocialPlatform?
    @State private var selection = Set<SocialPost>()
    @State private var showingComparison = false

    private var filteredSorted: [SocialPost] {
        let filtered = platformFilter == nil ? allPosts : allPosts.filter { $0.platform == platformFilter }
        switch sortOption {
        case .views: return filtered.sorted { ($0.latestSnapshot?.views ?? -1) > ($1.latestSnapshot?.views ?? -1) }
        case .likes: return filtered.sorted { ($0.latestSnapshot?.likes ?? -1) > ($1.latestSnapshot?.likes ?? -1) }
        case .comments: return filtered.sorted { ($0.latestSnapshot?.comments ?? -1) > ($1.latestSnapshot?.comments ?? -1) }
        case .shares: return filtered.sorted { ($0.latestSnapshot?.shares ?? -1) > ($1.latestSnapshot?.shares ?? -1) }
        case .engagement: return filtered.sorted { ($0.engagementRate ?? -1) > ($1.engagementRate ?? -1) }
        case .newest: return filtered.sorted { $0.publishedAt > $1.publishedAt }
        case .oldest: return filtered.sorted { $0.publishedAt < $1.publishedAt }
        }
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(filteredSorted, id: \.self) { post in
                NavigationLink {
                    SocialPostDetailView(post: post)
                } label: {
                    PostRow(post: post)
                }
                .tag(post)
            }
        }
        .overlay {
            if filteredSorted.isEmpty {
                ContentUnavailableView("Keine Posts", systemImage: "chart.bar.doc.horizontal", description: Text("Erfasse Posts über Social Accounts."))
            }
        }
        .environment(\.editMode, .constant(selection.isEmpty ? .inactive : .active))
        .navigationTitle("Content Performance")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Alle Plattformen") { platformFilter = nil }
                    ForEach(SocialPlatform.allCases) { platform in
                        Button(platform.displayName) { platformFilter = platform }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button(option.displayName) { sortOption = option }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
            if !selection.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    Button("Vergleichen (\(selection.count))") { showingComparison = true }
                }
            }
        }
        .sheet(isPresented: $showingComparison) {
            PostComparisonView(posts: Array(selection))
        }
    }
}

private struct PostRow: View {
    let post: SocialPost

    var body: some View {
        HStack {
            Image(systemName: post.platform.symbol).foregroundStyle(post.platform.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(post.caption ?? post.postType.displayName).lineLimit(1)
                HStack(spacing: 8) {
                    Label(post.latestSnapshot?.views.map(String.init) ?? "—", systemImage: "eye")
                    Label(post.latestSnapshot?.likes.map(String.init) ?? "—", systemImage: "heart")
                    Label(post.latestSnapshot?.shares.map(String.init) ?? "—", systemImage: "arrowshape.turn.up.right")
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
