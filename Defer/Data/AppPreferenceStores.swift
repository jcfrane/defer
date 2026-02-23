import Foundation

enum NotificationSettingsStore {
    enum Keys {
        static let remindersEnabled = "notifications.remindersEnabled"
        static let checkpointDueEnabled = "notifications.checkpointDueEnabled"
        static let midDelayNudgeEnabled = "notifications.midDelayNudgeEnabled"
        static let highRiskWindowEnabled = "notifications.highRiskWindowEnabled"
        static let postponeConfirmationEnabled = "notifications.postponeConfirmationEnabled"
        static let reminderTimeInterval = "notifications.reminderTimeInterval"
        static let highRiskWindowStartInterval = "notifications.highRiskWindowStartInterval"
        static let contextualPromptShown = "notifications.contextualPromptShown"
    }

    static func loadPreferences(defaults: UserDefaults = .standard) -> NotificationPreferences {
        NotificationPreferences(
            remindersEnabled: defaults.object(forKey: Keys.remindersEnabled) as? Bool ?? false,
            checkpointDueEnabled: defaults.object(forKey: Keys.checkpointDueEnabled) as? Bool ?? true,
            midDelayNudgeEnabled: defaults.object(forKey: Keys.midDelayNudgeEnabled) as? Bool ?? true,
            highRiskWindowEnabled: defaults.object(forKey: Keys.highRiskWindowEnabled) as? Bool ?? true,
            postponeConfirmationEnabled: defaults.object(forKey: Keys.postponeConfirmationEnabled) as? Bool ?? true,
            reminderTime: Date(timeIntervalSinceReferenceDate: reminderTimeInterval(defaults: defaults)),
            highRiskWindowStart: Date(timeIntervalSinceReferenceDate: highRiskWindowStartInterval(defaults: defaults))
        )
    }

    static func savePreferences(_ preferences: NotificationPreferences, defaults: UserDefaults = .standard) {
        defaults.set(preferences.remindersEnabled, forKey: Keys.remindersEnabled)
        defaults.set(preferences.checkpointDueEnabled, forKey: Keys.checkpointDueEnabled)
        defaults.set(preferences.midDelayNudgeEnabled, forKey: Keys.midDelayNudgeEnabled)
        defaults.set(preferences.highRiskWindowEnabled, forKey: Keys.highRiskWindowEnabled)
        defaults.set(preferences.postponeConfirmationEnabled, forKey: Keys.postponeConfirmationEnabled)
        defaults.set(preferences.reminderTime.timeIntervalSinceReferenceDate, forKey: Keys.reminderTimeInterval)
        defaults.set(preferences.highRiskWindowStart.timeIntervalSinceReferenceDate, forKey: Keys.highRiskWindowStartInterval)
    }

    static func setRemindersEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: Keys.remindersEnabled)
    }

    static func enableRecommendedDefaults(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: Keys.remindersEnabled)
        defaults.set(true, forKey: Keys.checkpointDueEnabled)
        defaults.set(true, forKey: Keys.midDelayNudgeEnabled)
        defaults.set(true, forKey: Keys.highRiskWindowEnabled)
        defaults.set(true, forKey: Keys.postponeConfirmationEnabled)

        if defaults.object(forKey: Keys.reminderTimeInterval) == nil {
            defaults.set(defaultReminderTimeInterval, forKey: Keys.reminderTimeInterval)
        }

        if defaults.object(forKey: Keys.highRiskWindowStartInterval) == nil {
            defaults.set(defaultHighRiskStartTimeInterval, forKey: Keys.highRiskWindowStartInterval)
        }
    }

    static func hasShownContextualPrompt(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: Keys.contextualPromptShown)
    }

    static func markContextualPromptShown(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: Keys.contextualPromptShown)
    }

    static func reminderTimeInterval(defaults: UserDefaults = .standard) -> TimeInterval {
        defaults.object(forKey: Keys.reminderTimeInterval) as? TimeInterval ?? defaultReminderTimeInterval
    }

    static func highRiskWindowStartInterval(defaults: UserDefaults = .standard) -> TimeInterval {
        defaults.object(forKey: Keys.highRiskWindowStartInterval) as? TimeInterval ?? defaultHighRiskStartTimeInterval
    }

    private static var defaultReminderTimeInterval: TimeInterval {
        normalizedTimeInterval(hour: 20, minute: 0)
    }

    private static var defaultHighRiskStartTimeInterval: TimeInterval {
        normalizedTimeInterval(hour: 18, minute: 30)
    }

    private static func normalizedTimeInterval(hour: Int, minute: Int) -> TimeInterval {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? .now
        return date.timeIntervalSinceReferenceDate
    }
}

enum AppBehaviorSettingsStore {
    enum Keys {
        static let whyReminderEnabled = "motivation.whyReminderEnabled"
        static let reflectionPromptEnabled = "decision.reflectionPromptEnabled"
    }

    static func isWhyReminderEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: Keys.whyReminderEnabled) as? Bool ?? true
    }

    static func setWhyReminderEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: Keys.whyReminderEnabled)
    }

    static func isReflectionPromptEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: Keys.reflectionPromptEnabled) as? Bool ?? true
    }

    static func setReflectionPromptEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: Keys.reflectionPromptEnabled)
    }

    // Legacy compatibility for older call sites.
    static func isStreakRecoveryEnabled(defaults: UserDefaults = .standard) -> Bool {
        isReflectionPromptEnabled(defaults: defaults)
    }

    static func setStreakRecoveryEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        setReflectionPromptEnabled(enabled, defaults: defaults)
    }
}

struct CurrencyOption: Identifiable, Hashable {
    let code: String
    let localizedName: String

    var id: String { code }

    var displayName: String {
        if localizedName == code {
            return code
        }

        return "\(code) - \(localizedName)"
    }
}

enum AppCurrencySettingsStore {
    enum Keys {
        static let currencyCode = "display.currencyCode"
    }

    static let defaultCurrencyCode = "USD"
    private static let supportedCurrencyCodes = Set(Locale.commonISOCurrencyCodes)

    static func selectedCurrencyCode(defaults: UserDefaults = .standard) -> String {
        normalizedCurrencyCode(defaults.string(forKey: Keys.currencyCode))
    }

    static func setSelectedCurrencyCode(_ currencyCode: String, defaults: UserDefaults = .standard) {
        defaults.set(normalizedCurrencyCode(currencyCode), forKey: Keys.currencyCode)
    }

    static func currencyOptions(locale: Locale = .current) -> [CurrencyOption] {
        Locale.commonISOCurrencyCodes
            .map { code in
                CurrencyOption(
                    code: code,
                    localizedName: localizedCurrencyName(for: code, locale: locale)
                )
            }
            .sorted { lhs, rhs in
                if lhs.code == defaultCurrencyCode {
                    return true
                }

                if rhs.code == defaultCurrencyCode {
                    return false
                }

                return lhs.code < rhs.code
            }
    }

    static func localizedCurrencyName(for currencyCode: String, locale: Locale = .current) -> String {
        locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
    }

    static func normalizedCurrencyCode(_ currencyCode: String?) -> String {
        let normalized = currencyCode?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard let normalized, supportedCurrencyCodes.contains(normalized) else {
            return defaultCurrencyCode
        }

        return normalized
    }
}

enum CurrencyAmountFormatter {
    static func wholeAmount(_ amount: Double, currencyCode: String, locale: Locale = .current) -> String {
        formattedAmount(
            amount,
            currencyCode: currencyCode,
            minimumFractionDigits: 0,
            maximumFractionDigits: 0,
            locale: locale
        )
    }

    static func formattedAmount(
        _ amount: Double,
        currencyCode: String,
        minimumFractionDigits: Int = 0,
        maximumFractionDigits: Int = 2,
        locale: Locale = .current
    ) -> String {
        let normalizedCode = AppCurrencySettingsStore.normalizedCurrencyCode(currencyCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = normalizedCode
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits

        if let formatted = formatter.string(from: NSNumber(value: amount)) {
            return formatted
        }

        return "\(normalizedCode) \(Int(amount.rounded()))"
    }
}
