import Foundation

enum AchievementRule {
    case minIntentionalDecisions(Int)
    case minUrgeLogs(Int)
    case minReflections(Int)
    case minDelayAdherence(rate: Double, samples: Int)
    case minResistedCount(Int)
    case minPostpones(Int)
    case minSavedSpend(Double)
    case minIntentionalRun(Int)
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
    let resolvedCount: Int
    let intentionalCount: Int
    let resistedCount: Int
    let postponeCount: Int
    let urgeLogCount: Int
    let reflectionCount: Int
    let delayAdherenceRate: Double
    let estimatedSpendAvoided: Double
    let maxIntentionalRun: Int

    static func from(
        defers: [DeferItem],
        completions: [CompletionHistory],
        urgeLogs: [UrgeLog]
    ) -> AchievementProgress {
        let resolved = completions.filter {
            $0.outcome != .postponed && $0.outcome != .canceled
        }

        let intentional = resolved.filter { $0.outcome.isIntentional }
        let resisted = resolved.filter { $0.outcome == .resisted }
        let postponeCount = completions.filter { $0.outcome == .postponed }.count
        let reflections = resolved.filter { !($0.reflection?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }
        let adherence = resolved.isEmpty ? 0 : Double(resolved.filter(\.wasAfterCheckpoint).count) / Double(resolved.count)
        let avoidedSpend = resisted.reduce(0) { partial, record in
            partial + (record.estimatedCost ?? 0)
        }

        let maxIntentionalRun = longestIntentionalRun(from: resolved)

        // Include unresolved intents with logged urge behavior for momentum-oriented achievements.
        let liveUrges = defers.reduce(0) { partial, item in
            partial + item.urgeLogs.count
        }

        return AchievementProgress(
            resolvedCount: resolved.count,
            intentionalCount: intentional.count,
            resistedCount: resisted.count,
            postponeCount: postponeCount,
            urgeLogCount: max(urgeLogs.count, liveUrges),
            reflectionCount: reflections.count,
            delayAdherenceRate: adherence,
            estimatedSpendAvoided: avoidedSpend,
            maxIntentionalRun: maxIntentionalRun
        )
    }

    private static func longestIntentionalRun(from resolved: [CompletionHistory]) -> Int {
        var current = 0
        var best = 0

        for record in resolved.sorted(by: { $0.completedAt < $1.completedAt }) {
            if record.outcome.isIntentional {
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
            key: "first_intentional_choice",
            title: "First Intentional Choice",
            details: "Resolve one intent with a deliberate outcome.",
            tier: .bronze,
            icon: "sparkles",
            rule: .minIntentionalDecisions(1)
        ),
        AchievementDefinition(
            key: "intentional_5",
            title: "Intentional Five",
            details: "Complete 5 decisions with intentional outcomes.",
            tier: .silver,
            icon: "checkmark.seal.fill",
            rule: .minIntentionalDecisions(5)
        ),
        AchievementDefinition(
            key: "urge_navigator_10",
            title: "Urge Navigator",
            details: "Log 10 urge moments during your waits.",
            tier: .bronze,
            icon: "waveform.path.ecg",
            rule: .minUrgeLogs(10)
        ),
        AchievementDefinition(
            key: "reflection_5",
            title: "Reflection Practice",
            details: "Add reflections to 5 resolved decisions.",
            tier: .silver,
            icon: "text.book.closed.fill",
            rule: .minReflections(5)
        ),
        AchievementDefinition(
            key: "delay_adherence_70",
            title: "Delay Keeper",
            details: "Maintain 70% delay adherence across 10 decisions.",
            tier: .gold,
            icon: "clock.badge.checkmark",
            rule: .minDelayAdherence(rate: 0.7, samples: 10)
        ),
        AchievementDefinition(
            key: "strategic_postpone_3",
            title: "Strategic Postponer",
            details: "Postpone 3 checkpoints instead of deciding impulsively.",
            tier: .silver,
            icon: "calendar.badge.clock",
            rule: .minPostpones(3)
        ),
        AchievementDefinition(
            key: "resisted_10",
            title: "Impulse Shield",
            details: "Record 10 resisted outcomes.",
            tier: .gold,
            icon: "shield.checkered",
            rule: .minResistedCount(10)
        ),
        AchievementDefinition(
            key: "saved_100",
            title: "Budget Guardian",
            details: "Avoid an estimated $100 through resisted choices.",
            tier: .legend,
            icon: "dollarsign.circle.fill",
            rule: .minSavedSpend(100)
        ),
        AchievementDefinition(
            key: "intentional_run_7",
            title: "Decision Streak",
            details: "Hit 7 intentional outcomes in a row.",
            tier: .legend,
            icon: "chart.line.uptrend.xyaxis",
            rule: .minIntentionalRun(7)
        )
    ]

    static func definition(for key: String) -> AchievementDefinition? {
        all.first { $0.key == key }
    }
}

extension AchievementRule {
    func isSatisfied(by progress: AchievementProgress) -> Bool {
        switch self {
        case .minIntentionalDecisions(let count):
            return progress.intentionalCount >= count
        case .minUrgeLogs(let count):
            return progress.urgeLogCount >= count
        case .minReflections(let count):
            return progress.reflectionCount >= count
        case .minDelayAdherence(let rate, let samples):
            return progress.resolvedCount >= samples && progress.delayAdherenceRate >= rate
        case .minResistedCount(let count):
            return progress.resistedCount >= count
        case .minPostpones(let count):
            return progress.postponeCount >= count
        case .minSavedSpend(let amount):
            return progress.estimatedSpendAvoided >= amount
        case .minIntentionalRun(let count):
            return progress.maxIntentionalRun >= count
        }
    }

    func progressText(using progress: AchievementProgress) -> String {
        switch self {
        case .minIntentionalDecisions(let target):
            return "\(min(progress.intentionalCount, target))/\(target) intentional"
        case .minUrgeLogs(let target):
            return "\(min(progress.urgeLogCount, target))/\(target) urge logs"
        case .minReflections(let target):
            return "\(min(progress.reflectionCount, target))/\(target) reflections"
        case .minDelayAdherence(let rate, let samples):
            let percent = Int((progress.delayAdherenceRate * 100).rounded())
            let goal = Int((rate * 100).rounded())
            return "\(percent)% / \(goal)% across \(samples)+"
        case .minResistedCount(let target):
            return "\(min(progress.resistedCount, target))/\(target) resisted"
        case .minPostpones(let target):
            return "\(min(progress.postponeCount, target))/\(target) postpones"
        case .minSavedSpend(let amount):
            let current = Int(progress.estimatedSpendAvoided.rounded())
            return "$\(min(current, Int(amount)))/$\(Int(amount)) saved"
        case .minIntentionalRun(let target):
            return "Run \(min(progress.maxIntentionalRun, target))/\(target)"
        }
    }

    func progressValue(using progress: AchievementProgress) -> (current: Int, target: Int) {
        switch self {
        case .minIntentionalDecisions(let target):
            return (progress.intentionalCount, target)
        case .minUrgeLogs(let target):
            return (progress.urgeLogCount, target)
        case .minReflections(let target):
            return (progress.reflectionCount, target)
        case .minDelayAdherence(let rate, let samples):
            let current = progress.resolvedCount >= samples
                ? Int((progress.delayAdherenceRate * 100).rounded())
                : Int((Double(progress.resolvedCount) / Double(max(samples, 1))) * 100)
            let target = Int((rate * 100).rounded())
            return (current, target)
        case .minResistedCount(let target):
            return (progress.resistedCount, target)
        case .minPostpones(let target):
            return (progress.postponeCount, target)
        case .minSavedSpend(let amount):
            return (Int(progress.estimatedSpendAvoided.rounded()), Int(amount))
        case .minIntentionalRun(let target):
            return (progress.maxIntentionalRun, target)
        }
    }
}
