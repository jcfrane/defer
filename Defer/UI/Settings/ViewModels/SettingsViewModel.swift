import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var remindersEnabled: Bool {
        didSet {
            NotificationSettingsStore.setRemindersEnabled(remindersEnabled, defaults: defaults)
        }
    }

    @Published var reflectionPromptEnabled: Bool {
        didSet {
            AppBehaviorSettingsStore.setReflectionPromptEnabled(reflectionPromptEnabled, defaults: defaults)
        }
    }

    @Published var whyReminderEnabled: Bool {
        didSet {
            AppBehaviorSettingsStore.setWhyReminderEnabled(whyReminderEnabled, defaults: defaults)
        }
    }

    @Published var currencyCode: String {
        didSet {
            AppCurrencySettingsStore.setSelectedCurrencyCode(currencyCode, defaults: defaults)
        }
    }

    @Published var authorizationState: LocalNotificationAuthorizationState = .notDetermined

    let currencyOptions: [CurrencyOption]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.currencyOptions = AppCurrencySettingsStore.currencyOptions()

        let preferences = NotificationSettingsStore.loadPreferences(defaults: defaults)
        self.remindersEnabled = preferences.remindersEnabled
        self.reflectionPromptEnabled = AppBehaviorSettingsStore.isReflectionPromptEnabled(defaults: defaults)
        self.whyReminderEnabled = AppBehaviorSettingsStore.isWhyReminderEnabled(defaults: defaults)
        self.currencyCode = AppCurrencySettingsStore.selectedCurrencyCode(defaults: defaults)
    }

    var notificationBadgeText: String {
        switch authorizationState {
        case .enabled where remindersEnabled:
            return "Enabled"
        case .enabled:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        case .denied:
            return "Blocked"
        case .unknown:
            return "Unknown"
        }
    }

    var notificationBadgeIcon: String {
        switch authorizationState {
        case .enabled where remindersEnabled:
            return "bell.badge.fill"
        case .enabled, .notDetermined:
            return "bell"
        case .denied:
            return "bell.slash.fill"
        case .unknown:
            return "exclamationmark.triangle.fill"
        }
    }

    var notificationBadgeTone: Color {
        switch authorizationState {
        case .enabled where remindersEnabled:
            return DeferTheme.success
        case .enabled:
            return DeferTheme.textMuted
        case .notDetermined:
            return DeferTheme.warning
        case .denied:
            return DeferTheme.danger
        case .unknown:
            return DeferTheme.warning
        }
    }

    var notificationIconTone: Color {
        switch authorizationState {
        case .enabled where remindersEnabled:
            return DeferTheme.textPrimary
        case .enabled:
            return DeferTheme.textMuted
        case .notDetermined:
            return DeferTheme.warning
        case .denied:
            return DeferTheme.danger
        case .unknown:
            return DeferTheme.warning
        }
    }

    var notificationSummaryText: String {
        switch authorizationState {
        case .enabled where remindersEnabled:
            return "Decision reminders are enabled."
        case .enabled:
            return "Decision reminders are disabled."
        case .notDetermined:
            return "Turn this on to request permission and enable reminders."
        case .denied:
            return "Notifications are blocked in iOS Settings."
        case .unknown:
            return "Notification permission status is unavailable right now."
        }
    }

    var isPermissionBlocked: Bool {
        authorizationState == .denied
    }

    private var fixedPreferences: NotificationPreferences {
        let reminderTime = Date(
            timeIntervalSinceReferenceDate: NotificationSettingsStore.reminderTimeInterval(defaults: defaults)
        )
        let highRiskWindowStart = Date(
            timeIntervalSinceReferenceDate: NotificationSettingsStore.highRiskWindowStartInterval(defaults: defaults)
        )

        return NotificationPreferences(
            remindersEnabled: remindersEnabled,
            checkpointDueEnabled: true,
            midDelayNudgeEnabled: true,
            highRiskWindowEnabled: true,
            postponeConfirmationEnabled: true,
            reminderTime: reminderTime,
            highRiskWindowStart: highRiskWindowStart
        )
    }

    func setRemindersEnabled(_ value: Bool) {
        guard value != remindersEnabled else { return }
        remindersEnabled = value
        AppHaptics.impact(.light)
    }

    func setReflectionPromptEnabled(_ value: Bool) {
        guard value != reflectionPromptEnabled else { return }
        reflectionPromptEnabled = value
        AppHaptics.selection()
    }

    func setWhyReminderEnabled(_ value: Bool) {
        guard value != whyReminderEnabled else { return }
        whyReminderEnabled = value
        AppHaptics.selection()
    }

    func setCurrencyCode(_ value: String) {
        let normalizedCode = AppCurrencySettingsStore.normalizedCurrencyCode(value)
        guard normalizedCode != currencyCode else { return }
        currencyCode = normalizedCode
        AppHaptics.selection()
    }

    func handleRemindersToggleChanged(activeItems: [DeferItem]) async {
        if remindersEnabled {
            NotificationSettingsStore.enableRecommendedDefaults(defaults: defaults)
            authorizationState = await LocalNotificationManager.requestAuthorizationIfNeeded()

            if authorizationState != .enabled {
                remindersEnabled = false
                AppHaptics.warning()
                await syncNotifications(activeItems: activeItems)
                return
            }
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
            preferences: fixedPreferences,
            activeItems: activeItems
        )
    }
}
