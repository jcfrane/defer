import Foundation
import UserNotifications

enum LocalNotificationAuthorizationState: Equatable {
    case enabled
    case denied
    case notDetermined
    case unknown

    init(status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .provisional, .ephemeral:
            self = .enabled
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .unknown
        }
    }

    var summaryText: String {
        switch self {
        case .enabled:
            return "Enabled"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not requested"
        case .unknown:
            return "Unknown"
        }
    }
}

struct NotificationPreferences: Equatable {
    var remindersEnabled: Bool
    var dailyCheckInEnabled: Bool
    var milestoneEnabled: Bool
    var targetApproachingEnabled: Bool
    var reminderTime: Date

    var hasAnyScheduleEnabled: Bool {
        remindersEnabled && (dailyCheckInEnabled || milestoneEnabled || targetApproachingEnabled)
    }
}

enum LocalNotificationManager {
    private static let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let dailyCheckIn = "local.daily-check-in"
        static let milestonePrefix = "local.milestone."
        static let targetPrefix = "local.target."
    }

    static func authorizationState() async -> LocalNotificationAuthorizationState {
        let settings = await center.notificationSettings()
        return LocalNotificationAuthorizationState(status: settings.authorizationStatus)
    }

    static func requestAuthorizationIfNeeded() async -> LocalNotificationAuthorizationState {
        let state = await authorizationState()
        switch state {
        case .enabled, .denied, .unknown:
            return state
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted ? .enabled : .denied
        }
    }

    static func syncNotifications(preferences: NotificationPreferences, activeItems: [DeferItem]) async {
        let identifiersToRemove = await pendingManagedIdentifiers()
        if !preferences.hasAnyScheduleEnabled {
            if !identifiersToRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }
            return
        }

        let state = await authorizationState()
        guard state == .enabled else {
            if !identifiersToRemove.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            }
            return
        }

        var requests: [UNNotificationRequest] = []

        if preferences.dailyCheckInEnabled,
           let daily = makeDailyCheckInRequest(reminderTime: preferences.reminderTime) {
            requests.append(daily)
        }

        if preferences.milestoneEnabled {
            requests.append(contentsOf: makeMilestoneRequests(for: activeItems, reminderTime: preferences.reminderTime))
        }

        if preferences.targetApproachingEnabled {
            requests.append(contentsOf: makeTargetApproachingRequests(for: activeItems, reminderTime: preferences.reminderTime))
        }

        if !identifiersToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }

        for request in requests.prefix(60) {
            try? await center.add(request)
        }
    }

    private static func pendingManagedIdentifiers() async -> [String] {
        let requests = await center.pendingNotificationRequests()
        return requests
            .map(\.identifier)
            .filter { id in
                id == Identifier.dailyCheckIn
                    || id.hasPrefix(Identifier.milestonePrefix)
                    || id.hasPrefix(Identifier.targetPrefix)
            }
    }

    private static func makeDailyCheckInRequest(reminderTime: Date) -> UNNotificationRequest? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }

        var triggerComponents = DateComponents()
        triggerComponents.hour = hour
        triggerComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Daily check-in"
        content.body = "Take a moment to protect your streak today."
        content.sound = .default

        return UNNotificationRequest(identifier: Identifier.dailyCheckIn, content: content, trigger: trigger)
    }

    private static func makeMilestoneRequests(for items: [DeferItem], reminderTime: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let milestonePercents: [Double] = [0.25, 0.5, 0.75]
        let validItems = items.filter { $0.status == .active && $0.targetDate > .now }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else {
            return []
        }

        var requests: [UNNotificationRequest] = []
        for item in validItems {
            let totalSeconds = item.targetDate.timeIntervalSince(item.startDate)
            guard totalSeconds > 0 else { continue }

            for percent in milestonePercents {
                let milestoneDate = item.startDate.addingTimeInterval(totalSeconds * percent)
                guard milestoneDate > .now else { continue }

                guard let scheduled = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: milestoneDate
                ) else {
                    continue
                }

                guard scheduled > .now else { continue }

                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let content = UNMutableNotificationContent()
                let percentInt = Int(percent * 100)
                content.title = "Milestone: \(item.title)"
                content.body = "You reached \(percentInt)% of your defer timeline. Keep going."
                content.sound = .default

                let identifier = "\(Identifier.milestonePrefix)\(item.id.uuidString).\(percentInt)"
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
        }

        return requests
    }

    private static func makeTargetApproachingRequests(for items: [DeferItem], reminderTime: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let dayOffsets = [3, 1]
        let validItems = items.filter { $0.status == .active && $0.targetDate > .now }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else {
            return []
        }

        var requests: [UNNotificationRequest] = []

        for item in validItems {
            for offset in dayOffsets {
                guard let reminderDate = calendar.date(byAdding: .day, value: -offset, to: item.targetDate) else {
                    continue
                }

                guard let scheduled = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: reminderDate
                ) else {
                    continue
                }

                guard scheduled > .now else { continue }

                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let content = UNMutableNotificationContent()
                content.title = "Target approaching"
                content.body = "\(item.title) ends in \(offset) day\(offset == 1 ? "" : "s"). Stay locked in."
                content.sound = .default

                let identifier = "\(Identifier.targetPrefix)\(item.id.uuidString).d\(offset)"
                requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
            }
        }

        return requests
    }
}
