import SwiftUI
import SwiftData

/// Verwaltung der vier Plattform-Accounts. Solange kein Backend (§29) angebunden ist,
/// werden Accounts/Posts/Snapshots manuell erfasst - die Datenstruktur ist exakt die, die
/// ein späterer automatischer Sync ebenfalls befüllen würde.
struct ManageSocialAccountsView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [SocialAccount]
    @State private var showingNewAccount = false
    @State private var isSyncing = false
    @State private var syncMessage: String?
    private var settings = AppSettings.shared

    var body: some View {
        List {
            ForEach(accounts) { account in
                NavigationLink {
                    SocialAccountDetailView(account: account)
                } label: {
                    HStack {
                        Image(systemName: account.platform.symbol).foregroundStyle(account.platform.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.displayName)
                            Text("@\(account.username)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let error = account.lastSyncError {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                .help(error.displayName)
                        } else if let count = account.followerCount {
                            Text("\(count) Follower").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { indices in
                for index in indices { context.delete(accounts[index]) }
            }

            Section {
                Button {
                    Task { await syncNow() }
                } label: {
                    if isSyncing {
                        ProgressView()
                    } else {
                        Label("Jetzt synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .disabled(isSyncing || accounts.isEmpty)
                if let syncMessage {
                    Text(syncMessage).font(.caption).foregroundStyle(.secondary)
                }
            } footer: {
                Text("Ohne verbundenes Backend schlägt der Sync erwartungsgemäß fehl (kein Scraping, nur offizielle APIs). Siehe SOCIAL_ANALYTICS_SETUP.md.")
            }
        }
        .overlay {
            if accounts.isEmpty {
                ContentUnavailableView("Keine Accounts", systemImage: "person.crop.circle.badge.plus", description: Text("Lege einen Account je Plattform an, um Posts und Kennzahlen zu erfassen."))
            }
        }
        .navigationTitle("Social Accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewAccount = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingNewAccount) {
            NewSocialAccountSheet()
        }
    }

    private func syncNow() async {
        isSyncing = true
        defer { isSyncing = false }
        let result = await SocialAnalyticsSyncScheduler.syncAll(context: context)
        if result.errors.isEmpty {
            syncMessage = "\(result.accountsSynced) Accounts, \(result.postsUpdated) Posts aktualisiert."
        } else {
            syncMessage = result.errors.first
        }
    }
}

private struct NewSocialAccountSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var platform: SocialPlatform = .instagram
    @State private var username = ""
    @State private var displayName = ""
    @State private var followerCount = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Plattform", selection: $platform) {
                    ForEach(SocialPlatform.allCases) { platform in
                        Label(platform.displayName, systemImage: platform.symbol).tag(platform)
                    }
                }
                .pickerStyle(.navigationLink)
                TextField("Benutzername (ohne @)", text: $username)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                TextField("Anzeigename", text: $displayName)
                TextField("Follower (optional)", text: $followerCount)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Neuer Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anlegen") {
                        let account = SocialAccount(
                            platform: platform,
                            externalAccountId: UUID().uuidString,
                            username: username,
                            displayName: displayName.isEmpty ? username : displayName,
                            followerCount: Int(followerCount)
                        )
                        context.insert(account)
                        dismiss()
                    }
                    .disabled(username.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
