import Foundation
import SwiftData

final class AchievementEngine {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func evaluateTriggers(at date: Date = .now, sourceDefer: DeferItem? = nil) throws -> [Achievement] {
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let existing = try context.fetch(achievementDescriptor)
        let existingKeys = Set(existing.map(\.key))

        let deferDescriptor = FetchDescriptor<DeferItem>()
        let completionDescriptor = FetchDescriptor<CompletionHistory>()
        let urgeDescriptor = FetchDescriptor<UrgeLog>()

        let progress = AchievementProgress.from(
            defers: try context.fetch(deferDescriptor),
            completions: try context.fetch(completionDescriptor),
            urgeLogs: try context.fetch(urgeDescriptor)
        )

        var unlocked: [Achievement] = []

        for definition in AchievementCatalog.all {
            guard !existingKeys.contains(definition.key) else { continue }
            guard definition.rule.isSatisfied(by: progress) else { continue }

            let achievement = Achievement(
                key: definition.key,
                title: definition.title,
                details: definition.details,
                tier: definition.tier,
                unlockedAt: date,
                sourceDeferID: sourceDefer?.id,
                createdAt: date,
                sourceDefer: sourceDefer
            )
            context.insert(achievement)
            unlocked.append(achievement)
        }

        if !unlocked.isEmpty {
            try context.save()
        }

        return unlocked
    }
}
