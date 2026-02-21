import Foundation

enum DeferCategory: String, Codable, CaseIterable, Identifiable {
    case health
    case spending
    case nutrition
    case habit
    case relationship
    case productivity
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .health: return "Health"
        case .spending: return "Spending"
        case .nutrition: return "Nutrition"
        case .habit: return "Habit"
        case .relationship: return "Relationship"
        case .productivity: return "Productivity"
        case .custom: return "Custom"
        }
    }
}

enum DeferType: String, Codable, CaseIterable, Identifiable {
    case abstinence
    case spending
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .abstinence: return "Behavior"
        case .spending: return "Purchase"
        case .custom: return "Custom"
        }
    }
}

enum DelayProtocolType: String, Codable, CaseIterable, Identifiable {
    case tenMinutes = "10m"
    case twentyFourHours = "24h"
    case seventyTwoHours = "72h"
    case untilPayday = "payday"
    case customDate = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tenMinutes:
            return "10 minutes"
        case .twentyFourHours:
            return "24 hours"
        case .seventyTwoHours:
            return "72 hours"
        case .untilPayday:
            return "Until payday"
        case .customDate:
            return "Custom date"
        }
    }

    var defaultDurationHours: Int {
        switch self {
        case .tenMinutes:
            return 1
        case .twentyFourHours:
            return 24
        case .seventyTwoHours:
            return 72
        case .untilPayday:
            return 24 * 14
        case .customDate:
            return 24
        }
    }
}

enum DecisionOutcome: String, Codable, CaseIterable, Identifiable {
    case resisted = "resisted"
    case intentionalYes = "intentional_yes"
    case postponed = "postponed"
    case gaveIn = "gave_in"
    case canceled = "canceled"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .resisted:
            return "Resisted"
        case .intentionalYes:
            return "Intentional yes"
        case .postponed:
            return "Postponed"
        case .gaveIn:
            return "Gave in"
        case .canceled:
            return "Canceled"
        }
    }

    var isIntentional: Bool {
        self == .resisted || self == .intentionalYes
    }
}

enum DeferStatus: String, Codable, CaseIterable, Identifiable {
    case activeWait = "active_wait"
    case checkpointDue = "checkpoint_due"
    case resolved = "resolved"
    case canceled = "canceled"

    // Legacy states kept so older previews/tools still compile.
    case active = "active"
    case completed = "completed"
    case failed = "failed"
    case paused = "paused"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .activeWait:
            return "In Delay"
        case .checkpointDue:
            return "Decision Due"
        case .resolved:
            return "Resolved"
        case .canceled:
            return "Canceled"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .paused:
            return "Paused"
        }
    }

    var normalizedLifecycle: DeferStatus {
        switch self {
        case .active, .paused:
            return .activeWait
        case .completed, .failed:
            return .resolved
        case .activeWait, .checkpointDue, .resolved, .canceled:
            return self
        }
    }

    var isTerminal: Bool {
        switch self {
        case .resolved, .canceled, .completed, .failed:
            return true
        case .activeWait, .checkpointDue, .active, .paused:
            return false
        }
    }

    var isDecisionPending: Bool {
        switch normalizedLifecycle {
        case .activeWait, .checkpointDue:
            return true
        case .resolved, .canceled:
            return false
        default:
            return false
        }
    }
}

enum StreakEntryStatus: String, Codable, CaseIterable, Identifiable {
    case success
    case failed
    case skipped

    var id: String { rawValue }
}

enum AchievementTier: String, Codable, CaseIterable, Identifiable {
    case bronze
    case silver
    case gold
    case legend

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .legend: return "Legend"
        }
    }
}
