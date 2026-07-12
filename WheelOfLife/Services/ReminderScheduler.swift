import SwiftUI
import UserNotifications
import Combine

enum ReminderFrequency: String, CaseIterable, Identifiable, Codable {
    case weekly
    case biweekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "Every week"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Every month"
        }
    }
}

@MainActor
final class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler()
    static let notificationID = "wol.reassessment.reminder"

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.enabled) }
    }

    @Published var frequency: ReminderFrequency {
        didSet { UserDefaults.standard.set(frequency.rawValue, forKey: Keys.frequency) }
    }

    /// 1 = Sunday … 7 = Saturday
    @Published var weekday: Int {
        didSet { UserDefaults.standard.set(weekday, forKey: Keys.weekday) }
    }

    @Published var hour: Int {
        didSet { UserDefaults.standard.set(hour, forKey: Keys.hour) }
    }

    @Published var minute: Int {
        didSet { UserDefaults.standard.set(minute, forKey: Keys.minute) }
    }

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private enum Keys {
        static let enabled = "wol_reminder_enabled"
        static let frequency = "wol_reminder_frequency"
        static let weekday = "wol_reminder_weekday"
        static let hour = "wol_reminder_hour"
        static let minute = "wol_reminder_minute"
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        let freq = UserDefaults.standard.string(forKey: Keys.frequency) ?? ReminderFrequency.weekly.rawValue
        self.frequency = ReminderFrequency(rawValue: freq) ?? .weekly
        self.weekday = (UserDefaults.standard.object(forKey: Keys.weekday) as? Int) ?? 1
        self.hour = (UserDefaults.standard.object(forKey: Keys.hour) as? Int) ?? 10
        self.minute = (UserDefaults.standard.object(forKey: Keys.minute) as? Int) ?? 0
    }

    func refreshAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
            return granted
        } catch {
            await refreshAuthorization()
            return false
        }
    }

    func applySettings() async {
        await refreshAuthorization()

        guard isEnabled else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
            return
        }

        if authorizationStatus == .notDetermined {
            let granted = await requestPermission()
            guard granted else {
                isEnabled = false
                return
            }
        }

        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            isEnabled = false
            return
        }

        await schedule()
    }

    private func schedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Check your Wheel of Life"
        content.body = "A quick re-rate keeps your balance honest. Open the app and update your scores."
        content.sound = .default

        let trigger: UNNotificationTrigger
        switch frequency {
        case .weekly:
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        case .biweekly:
            let next = nextDate(weekday: weekday, hour: hour, minute: minute)
            let delay = max(next.timeIntervalSinceNow, 60)
            // Fire once at the next preferred slot; reschedule on next app launch for the following cycle.
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        case .monthly:
            var components = DateComponents()
            components.day = min(Calendar.current.component(.day, from: Date()), 28)
            components.hour = hour
            components.minute = minute
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }

        let request = UNNotificationRequest(
            identifier: Self.notificationID,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Call on launch so biweekly one-shots keep chaining.
    func rescheduleIfNeeded() async {
        guard isEnabled else { return }
        await applySettings()
    }

    private func nextDate(weekday: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return Calendar.current.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
    }

    var timeLabel: String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    var weekdayLabel: String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(0, min(symbols.count - 1, weekday - 1))
        return symbols[index]
    }
}
