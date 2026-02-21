import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var remindersEnabled: Bool {
        didSet { NotificationSettingsStore.setRemindersEnabled(remindersEnabled, defaults: defaults) }
    }

    @Published var checkpointDueEnabled: Bool {
        didSet { defaults.set(checkpointDueEnabled, forKey: NotificationSettingsStore.Keys.checkpointDueEnabled) }
    }

    @Published var midDelayNudgeEnabled: Bool {
        didSet { defaults.set(midDelayNudgeEnabled, forKey: NotificationSettingsStore.Keys.midDelayNudgeEnabled) }
    }

    @Published var highRiskWindowEnabled: Bool {
        didSet { defaults.set(highRiskWindowEnabled, forKey: NotificationSettingsStore.Keys.highRiskWindowEnabled) }
    }

    @Published var postponeConfirmationEnabled: Bool {
        didSet { defaults.set(postponeConfirmationEnabled, forKey: NotificationSettingsStore.Keys.postponeConfirmationEnabled) }
    }

    @Published var reminderTimeInterval: TimeInterval {
        didSet { defaults.set(reminderTimeInterval, forKey: NotificationSettingsStore.Keys.reminderTimeInterval) }
    }

    @Published var highRiskWindowStartInterval: TimeInterval {
        didSet { defaults.set(highRiskWindowStartInterval, forKey: NotificationSettingsStore.Keys.highRiskWindowStartInterval) }
    }

    @Published var reflectionPromptEnabled: Bool {
        didSet { AppBehaviorSettingsStore.setReflectionPromptEnabled(reflectionPromptEnabled, defaults: defaults) }
    }

    @Published var whyReminderEnabled: Bool {
        didSet { AppBehaviorSettingsStore.setWhyReminderEnabled(whyReminderEnabled, defaults: defaults) }
    }

    @Published var authorizationState: LocalNotificationAuthorizationState = .notDetermined
    @Published var showNotificationOnboarding = false
    @Published var exportFileURL: URL?
    @Published var exportErrorMessage: String?

    private let defaults: UserDefaults
    private let exportService: DataExportService

    init(
        defaults: UserDefaults = .standard,
        exportService: DataExportService? = nil
    ) {
        self.defaults = defaults
        self.exportService = exportService ?? DataExportService()

        let preferences = NotificationSettingsStore.loadPreferences(defaults: defaults)
        self.remindersEnabled = preferences.remindersEnabled
        self.checkpointDueEnabled = preferences.checkpointDueEnabled
        self.midDelayNudgeEnabled = preferences.midDelayNudgeEnabled
        self.highRiskWindowEnabled = preferences.highRiskWindowEnabled
        self.postponeConfirmationEnabled = preferences.postponeConfirmationEnabled
        self.reminderTimeInterval = preferences.reminderTime.timeIntervalSinceReferenceDate
        self.highRiskWindowStartInterval = preferences.highRiskWindowStart.timeIntervalSinceReferenceDate
        self.reflectionPromptEnabled = AppBehaviorSettingsStore.isReflectionPromptEnabled(defaults: defaults)
        self.whyReminderEnabled = AppBehaviorSettingsStore.isWhyReminderEnabled(defaults: defaults)
    }

    var hasEnabledReminderType: Bool {
        checkpointDueEnabled || midDelayNudgeEnabled || highRiskWindowEnabled || postponeConfirmationEnabled
    }

    var enabledReminderTypeCount: Int {
        [checkpointDueEnabled, midDelayNudgeEnabled, highRiskWindowEnabled, postponeConfirmationEnabled].filter { $0 }.count
    }

    var reminderTimeText: String {
        Date(timeIntervalSinceReferenceDate: reminderTimeInterval)
            .formatted(date: .omitted, time: .shortened)
    }

    var highRiskWindowText: String {
        Date(timeIntervalSinceReferenceDate: highRiskWindowStartInterval)
            .formatted(date: .omitted, time: .shortened)
    }

    var reminderProfileTitle: String {
        switch authorizationState {
        case .enabled where remindersEnabled && hasEnabledReminderType:
            return "Actively guiding decisions"
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
            return "Checkpoint reminders run at \(reminderTimeText), high-risk nudges at \(highRiskWindowText)."
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
            return "Configure checkpoint reminders, support nudges, and high-risk prompts from this screen."
        case .denied:
            return "Defer cannot deliver reminders until you re-enable notification access in iOS Settings."
        case .notDetermined:
            return "You have not granted access yet. Run setup to start receiving checkpoint notifications."
        case .unknown:
            return "Unable to read notification permission status right now. Try reopening the app."
        }
    }

    var preferences: NotificationPreferences {
        NotificationPreferences(
            remindersEnabled: remindersEnabled,
            checkpointDueEnabled: checkpointDueEnabled,
            midDelayNudgeEnabled: midDelayNudgeEnabled,
            highRiskWindowEnabled: highRiskWindowEnabled,
            postponeConfirmationEnabled: postponeConfirmationEnabled,
            reminderTime: Date(timeIntervalSinceReferenceDate: reminderTimeInterval),
            highRiskWindowStart: Date(timeIntervalSinceReferenceDate: highRiskWindowStartInterval)
        )
    }

    func setReminderTime(_ value: Date) {
        AppHaptics.selection()
        reminderTimeInterval = value.timeIntervalSinceReferenceDate
    }

    func setHighRiskWindowStart(_ value: Date) {
        AppHaptics.selection()
        highRiskWindowStartInterval = value.timeIntervalSinceReferenceDate
    }

    func setRemindersEnabled(_ value: Bool) {
        guard value != remindersEnabled else { return }
        remindersEnabled = value
        AppHaptics.impact(.light)
    }

    func setCheckpointDueEnabled(_ value: Bool) {
        guard value != checkpointDueEnabled else { return }
        checkpointDueEnabled = value
        AppHaptics.selection()
    }

    func setMidDelayNudgeEnabled(_ value: Bool) {
        guard value != midDelayNudgeEnabled else { return }
        midDelayNudgeEnabled = value
        AppHaptics.selection()
    }

    func setHighRiskWindowEnabled(_ value: Bool) {
        guard value != highRiskWindowEnabled else { return }
        highRiskWindowEnabled = value
        AppHaptics.selection()
    }

    func setPostponeConfirmationEnabled(_ value: Bool) {
        guard value != postponeConfirmationEnabled else { return }
        postponeConfirmationEnabled = value
        AppHaptics.selection()
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

    func exportBackup(
        format: DataExportFormat,
        defers: [DeferItem],
        completions: [CompletionHistory],
        achievements: [Achievement]
    ) {
        do {
            exportFileURL = try exportService.export(
                format: format,
                defers: defers,
                completions: completions,
                achievements: achievements
            )
            exportErrorMessage = nil
            AppHaptics.success()
        } catch {
            exportErrorMessage = error.localizedDescription
            AppHaptics.error()
        }
    }

    func clearExportFile() {
        exportFileURL = nil
    }

    func clearExportError() {
        exportErrorMessage = nil
    }
}
