import Foundation
import SwiftData
import UserNotifications

/// Lokale Erinnerungen: geplante Veröffentlichungen (zum Zeitpunkt) und Konzerte
/// (am Vortag um 18:00). Beim Start/Vordergrund werden alle Erinnerungen neu aufgebaut,
/// damit Terminänderungen und Status-Wechsel berücksichtigt sind.
enum ReminderService {
    private static let prefix = "tkc.reminder."
    private static let maxPending = 60

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    @MainActor
    static func rescheduleAll(context: ModelContext) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })

        guard AppSettings.shared.remindersEnabled else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        var requests: [(date: Date, request: UNNotificationRequest)] = []
        let now = Date.now
        let calendar = Calendar.current

        let items = (try? context.fetch(FetchDescriptor<ContentItem>())) ?? []
        for item in items where !item.isUnplanned && item.status != .published && item.status != .discarded {
            guard let time = item.publishTime, time > now else { continue }
            requests.append((time, makeRequest(
                id: "\(prefix)content.\(item.persistentModelID.hashValue)",
                title: "Jetzt veröffentlichen: \(item.title)",
                body: "\(item.platform.displayName) · \(item.contentType.displayName)",
                fireAt: time
            )))
        }

        let concerts = (try? context.fetch(FetchDescriptor<Concert>())) ?? []
        for concert in concerts {
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: concert.date)),
                  let fire = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayBefore),
                  fire > now else { continue }
            requests.append((fire, makeRequest(
                id: "\(prefix)concert.\(concert.externalId)",
                title: "Morgen: \(concert.title)",
                body: "\(concert.venue), \(concert.city) - Stories und Posts vorbereitet?",
                fireAt: fire
            )))
        }

        // iOS erlaubt maximal 64 ausstehende lokale Benachrichtigungen: die nächsten zuerst.
        for entry in requests.sorted(by: { $0.date < $1.date }).prefix(maxPending) {
            try? await center.add(entry.request)
        }
    }

    private static func makeRequest(id: String, title: String, body: String, fireAt: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        return UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
    }
}
