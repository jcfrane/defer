import Foundation

enum AchievementRule {
    case minCompletions(Int)
    case minStreak(Int)
    case categoryMastery(Int)
    case consecutiveCompletions(Int)
}

struct AchievementDefinition: Identifiable {
    let key: String
    let title: String
    let details: String
    let tier: AchievementTier
    let icon: String
    let rule: AchievementRule

    var id: String { key }
}

struct AchievementProgress {
    let completionCount: Int
    let maxStreak: Int
    let highestCategoryCompletionCount: Int
    let maxConsecutiveCompletions: Int

    static func from(defers: [DeferItem], completions: [CompletionHistory]) -> AchievementProgress {
        let categoryCounts = Dictionary(grouping: completions, by: \.category)
            .mapValues(\.count)

        let highestCategoryCompletionCount = categoryCounts.values.max() ?? 0
        let maxStreak = defers.map(\.streakCount).max() ?? 0
        let maxConsecutiveCompletions = longestCompletionRun(from: defers)

        return AchievementProgress(
            completionCount: completions.count,
            maxStreak: maxStreak,
            highestCategoryCompletionCount: highestCategoryCompletionCount,
            maxConsecutiveCompletions: maxConsecutiveCompletions
        )
    }

    private static func longestCompletionRun(from defers: [DeferItem]) -> Int {
        let terminal = defers
            .filter { $0.status.isTerminal }
            .sorted { $0.updatedAt < $1.updatedAt }

        var current = 0
        var best = 0

        for deferItem in terminal {
            if deferItem.status == .completed {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        return best
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            key: "first_completion",
            title: "First Win",
            details: "Complete your first defer.",
            tier: .bronze,
            icon: "flag.checkered",
            rule: .minCompletions(1)
        ),
        AchievementDefinition(
            key: "streak_7",
            title: "7-Day Discipline",
            details: "Reach a 7-day streak.",
            tier: .bronze,
            icon: "flame.fill",
            rule: .minStreak(7)
        ),
        AchievementDefinition(
            key: "streak_30",
            title: "30-Day Focus",
            details: "Reach a 30-day streak.",
            tier: .silver,
            icon: "flame.circle.fill",
            rule: .minStreak(30)
        ),
        AchievementDefinition(
            key: "streak_100",
            title: "100-Day Mastery",
            details: "Reach a 100-day streak.",
            tier: .legend,
            icon: "bolt.fill",
            rule: .minStreak(100)
        ),
        AchievementDefinition(
            key: "category_mastery_3",
            title: "Category Specialist",
            details: "Complete 3 defers in one category.",
            tier: .silver,
            icon: "square.grid.2x2.fill",
            rule: .categoryMastery(3)
        ),
        AchievementDefinition(
            key: "category_mastery_10",
            title: "Category Master",
            details: "Complete 10 defers in one category.",
            tier: .gold,
            icon: "crown.fill",
            rule: .categoryMastery(10)
        ),
        AchievementDefinition(
            key: "completion_run_3",
            title: "Momentum Builder",
            details: "Finish 3 defers consecutively without a failed/canceled defer.",
            tier: .gold,
            icon: "chart.line.uptrend.xyaxis",
            rule: .consecutiveCompletions(3)
        ),
        AchievementDefinition(
            key: "completion_run_7",
            title: "Unstoppable",
            details: "Finish 7 defers consecutively without a failed/canceled defer.",
            tier: .legend,
            icon: "star.circle.fill",
            rule: .consecutiveCompletions(7)
        )
    ]

    static func definition(for key: String) -> AchievementDefinition? {
        all.first { $0.key == key }
    }
}

extension AchievementRule {
    func isSatisfied(by progress: AchievementProgress) -> Bool {
        switch self {
        case .minCompletions(let count):
            return progress.completionCount >= count
        case .minStreak(let count):
            return progress.maxStreak >= count
        case .categoryMastery(let count):
            return progress.highestCategoryCompletionCount >= count
        case .consecutiveCompletions(let count):
            return progress.maxConsecutiveCompletions >= count
        }
    }

    func progressText(using progress: AchievementProgress) -> String {
        switch self {
        case .minCompletions(let target):
            return "\(min(progress.completionCount, target))/\(target) completed"
        case .minStreak(let target):
            return "Best streak: \(min(progress.maxStreak, target))/\(target)"
        case .categoryMastery(let target):
            return "Best category: \(min(progress.highestCategoryCompletionCount, target))/\(target)"
        case .consecutiveCompletions(let target):
            return "Best run: \(min(progress.maxConsecutiveCompletions, target))/\(target)"
        }
    }
}
