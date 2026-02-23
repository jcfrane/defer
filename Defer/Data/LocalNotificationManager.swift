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
    var checkpointDueEnabled: Bool
    var midDelayNudgeEnabled: Bool
    var highRiskWindowEnabled: Bool
    var postponeConfirmationEnabled: Bool
    var reminderTime: Date
    var highRiskWindowStart: Date

    var hasAnyScheduleEnabled: Bool {
        remindersEnabled && (
            checkpointDueEnabled ||
            midDelayNudgeEnabled ||
            highRiskWindowEnabled ||
            postponeConfirmationEnabled
        )
    }
}

enum LocalNotificationManager {
    private static let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let checkpointPrefix = "local.checkpoint."
        static let midDelayPrefix = "local.mid-delay."
        static let highRiskDaily = "local.high-risk-window"
        static let postponePrefix = "local.postpone."
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

        if preferences.checkpointDueEnabled {
            requests.append(contentsOf: makeCheckpointDueRequests(for: activeItems))
        }

        if preferences.midDelayNudgeEnabled {
            requests.append(contentsOf: makeMidDelayRequests(for: activeItems))
        }

        if preferences.highRiskWindowEnabled,
           let highRiskRequest = makeHighRiskWindowRequest(startTime: preferences.highRiskWindowStart) {
            requests.append(highRiskRequest)
        }

        if preferences.postponeConfirmationEnabled {
            requests.append(contentsOf: makePostponeReminderRequests(for: activeItems, reminderTime: preferences.reminderTime))
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
                id.hasPrefix(Identifier.checkpointPrefix)
                    || id.hasPrefix(Identifier.midDelayPrefix)
                    || id == Identifier.highRiskDaily
                    || id.hasPrefix(Identifier.postponePrefix)
            }
    }

    private static func makeCheckpointDueRequests(for items: [DeferItem]) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let eligible = items.filter {
            $0.status.normalizedLifecycle == .activeWait && $0.targetDate > .now
        }

        return eligible.compactMap { item in
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: item.targetDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Checkpoint due"
            content.body = "\(item.title): decide now, postpone, or resist intentionally."
            content.sound = .default
            content.userInfo = [
                "event": DecisionAnalytics.notificationOpened,
                "intent_id": item.id.uuidString
            ]

            let identifier = "\(Identifier.checkpointPrefix)\(item.id.uuidString)"
            return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }

    private static func makeMidDelayRequests(for items: [DeferItem]) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let eligible = items.filter {
            $0.status.normalizedLifecycle == .activeWait &&
            $0.targetDate > .now &&
            $0.delayDurationHours >= 24
        }

        return eligible.compactMap { item in
            let midpointInterval = item.targetDate.timeIntervalSince(item.startDate) / 2
            let midpoint = item.startDate.addingTimeInterval(midpointInterval)
            guard midpoint > .now else { return nil }

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: midpoint)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Mid-delay support"
            content.body = item.fallbackAction?.isEmpty == false
                ? "Try your fallback: \(item.fallbackAction ?? "")"
                : "Pause for two breaths and revisit why this matters."
            content.sound = .default

            let identifier = "\(Identifier.midDelayPrefix)\(item.id.uuidString)"
            return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }

    private static func makeHighRiskWindowRequest(startTime: Date) -> UNNotificationRequest? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime)

        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }

        var triggerComponents = DateComponents()
        triggerComponents.hour = hour
        triggerComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "High-risk window"
        content.body = "If an urge hits, log it now and make an intentional choice at your checkpoint."
        content.sound = .default

        return UNNotificationRequest(identifier: Identifier.highRiskDaily, content: content, trigger: trigger)
    }

    private static func makePostponeReminderRequests(for items: [DeferItem], reminderTime: Date) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else {
            return []
        }

        let eligible = items.filter {
            $0.postponeCount > 0 &&
            $0.status.normalizedLifecycle == .activeWait &&
            $0.targetDate > .now
        }

        return eligible.compactMap { item in
            guard let scheduled = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: item.targetDate) else {
                return nil
            }

            guard scheduled > .now else { return nil }

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Postpone reminder"
            content.body = "\(item.title) was postponed. Keep the next checkpoint intentional."
            content.sound = .default

            let identifier = "\(Identifier.postponePrefix)\(item.id.uuidString)"
            return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        }
    }
}
