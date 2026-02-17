import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    enum Keys {
        static let remindersEnabled = "notifications.remindersEnabled"
        static let dailyCheckInEnabled = "notifications.dailyCheckInEnabled"
        static let milestoneEnabled = "notifications.milestoneEnabled"
        static let targetApproachingEnabled = "notifications.targetApproachingEnabled"
        static let reminderTimeInterval = "notifications.reminderTimeInterval"
    }

    @Published var remindersEnabled: Bool {
        didSet { defaults.set(remindersEnabled, forKey: Keys.remindersEnabled) }
    }

    @Published var dailyCheckInEnabled: Bool {
        didSet { defaults.set(dailyCheckInEnabled, forKey: Keys.dailyCheckInEnabled) }
    }

    @Published var milestoneEnabled: Bool {
        didSet { defaults.set(milestoneEnabled, forKey: Keys.milestoneEnabled) }
    }

    @Published var targetApproachingEnabled: Bool {
        didSet { defaults.set(targetApproachingEnabled, forKey: Keys.targetApproachingEnabled) }
    }

    @Published var reminderTimeInterval: TimeInterval {
        didSet { defaults.set(reminderTimeInterval, forKey: Keys.reminderTimeInterval) }
    }

    @Published var authorizationState: LocalNotificationAuthorizationState = .notDetermined
    @Published var showNotificationOnboarding = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.remindersEnabled = defaults.object(forKey: Keys.remindersEnabled) as? Bool ?? false
        self.dailyCheckInEnabled = defaults.object(forKey: Keys.dailyCheckInEnabled) as? Bool ?? true
        self.milestoneEnabled = defaults.object(forKey: Keys.milestoneEnabled) as? Bool ?? true
        self.targetApproachingEnabled = defaults.object(forKey: Keys.targetApproachingEnabled) as? Bool ?? true
        self.reminderTimeInterval = defaults.object(forKey: Keys.reminderTimeInterval) as? TimeInterval ?? Self.defaultReminderTimeInterval
    }

    var hasEnabledReminderType: Bool {
        dailyCheckInEnabled || milestoneEnabled || targetApproachingEnabled
    }

    var enabledReminderTypeCount: Int {
        [dailyCheckInEnabled, milestoneEnabled, targetApproachingEnabled].filter { $0 }.count
    }

    var reminderTimeText: String {
        Date(timeIntervalSinceReferenceDate: reminderTimeInterval)
            .formatted(date: .omitted, time: .shortened)
    }

    var reminderProfileTitle: String {
        switch authorizationState {
        case .enabled where remindersEnabled && hasEnabledReminderType:
            return "Actively guiding your streak"
        case .enabled where remindersEnabled:
            return "Schedule enabled, types muted"
        case .enabled:
            return "Permission ready, schedule off"
        case .notDetermined:
            return "Permission not requested"
        case .denied:
            return "Notifications blocked"
        case .unknown:
            return "Permission status unavailable"
        }
    }

    var reminderProfileSubtitle: String {
        switch authorizationState {
        case .enabled where remindersEnabled && hasEnabledReminderType:
            return "You will receive focused reminders at \(reminderTimeText)."
        case .enabled where remindersEnabled:
            return "Turn on at least one reminder type to start scheduling."
        case .enabled:
            return "Enable your reminder schedule anytime from below."
        case .notDetermined:
            return "Run setup to request access and unlock reminder controls."
        case .denied:
            return "Enable notification access in iOS Settings to continue."
        case .unknown:
            return "Reopen the app or check iOS settings to refresh status."
        }
    }

    var authorizationBadgeText: String {
        switch authorizationState {
        case .enabled:
            return "Allowed"
        case .denied:
            return "Blocked"
        case .notDetermined:
            return "Not Set"
        case .unknown:
            return "Unknown"
        }
    }

    var authorizationHeadlineText: String {
        switch authorizationState {
        case .enabled:
            return "Permission Granted"
        case .denied:
            return "Permission Denied"
        case .notDetermined:
            return "Permission Needed"
        case .unknown:
            return "Permission Unavailable"
        }
    }

    var authorizationIcon: String {
        switch authorizationState {
        case .enabled:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .unknown:
            return "exclamationmark.triangle.fill"
        }
    }

    var authorizationTone: Color {
        switch authorizationState {
        case .enabled:
            return DeferTheme.success
        case .denied:
            return DeferTheme.danger
        case .notDetermined, .unknown:
            return DeferTheme.warning
        }
    }

    var authorizationDetailText: String {
        switch authorizationState {
        case .enabled:
            return "Configure your schedule and choose exactly which reminder types should reach you."
        case .denied:
            return "Defer cannot deliver reminders until you re-enable notification access in iOS Settings."
        case .notDetermined:
            return "You have not granted access yet. Run setup to start receiving reminder notifications."
        case .unknown:
            return "Unable to read notification permission status right now. Try reopening the app."
        }
    }

    var preferences: NotificationPreferences {
        NotificationPreferences(
            remindersEnabled: remindersEnabled,
            dailyCheckInEnabled: dailyCheckInEnabled,
            milestoneEnabled: milestoneEnabled,
            targetApproachingEnabled: targetApproachingEnabled,
            reminderTime: Date(timeIntervalSinceReferenceDate: reminderTimeInterval)
        )
    }

    func setReminderTime(_ value: Date) {
        AppHaptics.selection()
        reminderTimeInterval = value.timeIntervalSinceReferenceDate
    }

    func setRemindersEnabled(_ value: Bool) {
        guard value != remindersEnabled else { return }
        remindersEnabled = value
        AppHaptics.impact(.light)
    }

    func setDailyCheckInEnabled(_ value: Bool) {
        guard value != dailyCheckInEnabled else { return }
        dailyCheckInEnabled = value
        AppHaptics.selection()
    }

    func setMilestoneEnabled(_ value: Bool) {
        guard value != milestoneEnabled else { return }
        milestoneEnabled = value
        AppHaptics.selection()
    }

    func setTargetApproachingEnabled(_ value: Bool) {
        guard value != targetApproachingEnabled else { return }
        targetApproachingEnabled = value
        AppHaptics.selection()
    }

    func handleRemindersToggleChanged(activeItems: [DeferItem]) async {
        if remindersEnabled {
            let state = await LocalNotificationManager.authorizationState()
            authorizationState = state
            if state == .notDetermined {
                remindersEnabled = false
                showNotificationOnboarding = true
                await syncNotifications(activeItems: activeItems)
                return
            }

            if state != .enabled {
                remindersEnabled = false
                AppHaptics.warning()
            }
        }

        await syncNotifications(activeItems: activeItems)
    }

    func continueFromNotificationOnboarding(activeItems: [DeferItem]) async {
        showNotificationOnboarding = false
        authorizationState = await LocalNotificationManager.requestAuthorizationIfNeeded()

        if authorizationState == .enabled {
            remindersEnabled = true
            AppHaptics.success()
        } else {
            AppHaptics.warning()
        }

        await syncNotifications(activeItems: activeItems)
    }

    func refreshNotificationState() async {
        authorizationState = await LocalNotificationManager.authorizationState()

        if authorizationState != .enabled && remindersEnabled {
            remindersEnabled = false
        }
    }

    func syncNotifications(activeItems: [DeferItem]) async {
        await LocalNotificationManager.syncNotifications(
            preferences: preferences,
            activeItems: activeItems
        )
    }

    private static var defaultReminderTimeInterval: TimeInterval {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = 20
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? .now
        return date.timeIntervalSinceReferenceDate
    }
}
