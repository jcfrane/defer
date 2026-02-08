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
        case .abstinence: return "Abstinence"
        case .spending: return "Spending"
        case .custom: return "Custom"
        }
    }
}

enum DeferStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case completed
    case failed
    case canceled
    case paused

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .canceled: return "Canceled"
        case .paused: return "Paused"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .canceled:
            return true
        case .active, .paused:
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
