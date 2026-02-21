import Foundation
import SwiftData

struct PreviewFixtureBundle {
    let activeItems: [DeferItem]
    let archivedItems: [DeferItem]
    let completions: [CompletionHistory]
    let achievements: [Achievement]
    let urgeLogs: [UrgeLog]

    var allItems: [DeferItem] {
        activeItems + archivedItems
    }
}

enum PreviewFixtures {
    static func sampleBundle(now: Date = .now) -> PreviewFixtureBundle {
        let calendar = Calendar.current

        let activeOne = sampleDefer(
            title: "No sugar tonight",
            details: "I sleep better when I pause this urge.",
            category: .nutrition,
            status: .activeWait,
            strictMode: false,
            streakCount: 0,
            startDate: calendar.date(byAdding: .hour, value: -6, to: now) ?? now,
            targetDate: calendar.date(byAdding: .hour, value: 18, to: now) ?? now
        )
        activeOne.delayProtocolType = .twentyFourHours
        activeOne.delayDurationHours = 24
        activeOne.fallbackAction = "Drink tea and wait 10 minutes."
        activeOne.estimatedCost = 9

        let dueOne = sampleDefer(
            title: "Impulse gadget purchase",
            details: "I want spending to match priorities.",
            category: .spending,
            status: .checkpointDue,
            strictMode: false,
            streakCount: 0,
            startDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
            targetDate: calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        )
        dueOne.delayProtocolType = .seventyTwoHours
        dueOne.delayDurationHours = 72
        dueOne.fallbackAction = "Leave it in cart for now."
        dueOne.estimatedCost = 149

        let activeTwo = sampleDefer(
            title: "Open social apps during focus block",
            details: "I want to protect deep work time.",
            category: .productivity,
            status: .activeWait,
            strictMode: false,
            streakCount: 0,
            startDate: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
            targetDate: calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        )
        activeTwo.delayProtocolType = .tenMinutes
        activeTwo.delayDurationHours = 1
        activeTwo.fallbackAction = "Write the next action for current task."

        let resolvedOne = sampleDefer(
            title: "Late-night delivery",
            details: "Avoid reactive ordering.",
            category: .spending,
            status: .resolved,
            strictMode: false,
            streakCount: 0,
            startDate: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: -6, to: now) ?? now
        )
        resolvedOne.outcome = .resisted
        resolvedOne.resolvedAt = calendar.date(byAdding: .day, value: -6, to: now)
        resolvedOne.estimatedCost = 42

        let resolvedTwo = sampleDefer(
            title: "Upgrade laptop today",
            details: "Only buy if it still matters after waiting.",
            category: .spending,
            status: .resolved,
            strictMode: false,
            streakCount: 0,
            startDate: calendar.date(byAdding: .day, value: -20, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: -18, to: now) ?? now
        )
        resolvedTwo.outcome = .intentionalYes
        resolvedTwo.resolvedAt = calendar.date(byAdding: .day, value: -17, to: now)
        resolvedTwo.estimatedCost = 999

        let resolvedThree = sampleDefer(
            title: "Reactive message",
            details: "Pause before replying emotionally.",
            category: .relationship,
            status: .resolved,
            strictMode: false,
            streakCount: 0,
            startDate: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
            delayProtocolType: .tenMinutes
        )
        resolvedThree.outcome = .gaveIn
        resolvedThree.resolvedAt = calendar.date(byAdding: .day, value: -4, to: now)

        let completions = [
            sampleCompletion(
                item: resolvedOne,
                completedAt: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                outcome: .resisted,
                reflection: "Waiting made the urge pass.",
                urgeScore: 4,
                regretScore: 1
            ),
            sampleCompletion(
                item: resolvedTwo,
                completedAt: calendar.date(byAdding: .day, value: -17, to: now) ?? now,
                outcome: .intentionalYes,
                reflection: "Still needed it after the pause.",
                urgeScore: 2,
                regretScore: 1
            ),
            sampleCompletion(
                item: resolvedThree,
                completedAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                outcome: .gaveIn,
                reflection: "I replied too quickly.",
                urgeScore: 5,
                regretScore: 4
            ),
            sampleCompletion(
                item: dueOne,
                completedAt: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                outcome: .postponed,
                reflection: "Postponed to tomorrow.",
                urgeScore: nil,
                regretScore: nil
            )
        ]

        let urgeLogs = [
            UrgeLog(
                deferID: activeOne.id,
                loggedAt: calendar.date(byAdding: .hour, value: -3, to: now) ?? now,
                intensity: 4,
                note: "Saw dessert post",
                usedFallbackAction: true,
                deferItem: activeOne
            ),
            UrgeLog(
                deferID: dueOne.id,
                loggedAt: calendar.date(byAdding: .hour, value: -2, to: now) ?? now,
                intensity: 5,
                note: "Flash sale email",
                usedFallbackAction: false,
                deferItem: dueOne
            ),
            UrgeLog(
                deferID: activeTwo.id,
                loggedAt: calendar.date(byAdding: .minute, value: -35, to: now) ?? now,
                intensity: 3,
                note: "Automatic app opening habit",
                usedFallbackAction: true,
                deferItem: activeTwo
            )
        ]

        let achievements = [
            sampleAchievement(key: "first_intentional_choice", sourceDefer: resolvedOne, unlockedAt: calendar.date(byAdding: .day, value: -6, to: now) ?? now),
            sampleAchievement(key: "urge_navigator_10", sourceDefer: activeOne, unlockedAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now)
        ]

        return PreviewFixtureBundle(
            activeItems: [activeOne, dueOne, activeTwo],
            archivedItems: [resolvedOne, resolvedTwo, resolvedThree],
            completions: completions,
            achievements: achievements,
            urgeLogs: urgeLogs
        )
    }

    static func sampleDefer(
        title: String,
        details: String,
        category: DeferCategory,
        status: DeferStatus,
        strictMode: Bool,
        streakCount: Int,
        startDate: Date,
        targetDate: Date,
        delayProtocolType: DelayProtocolType = .twentyFourHours
    ) -> DeferItem {
        let item = DeferItem(
            title: title,
            details: details,
            whyItMatters: details,
            category: category,
            type: type(for: category),
            startDate: startDate,
            targetDate: targetDate,
            status: status,
            outcome: nil,
            delayProtocolType: delayProtocolType,
            delayDurationHours: delayProtocolType.defaultDurationHours,
            estimatedCost: nil,
            fallbackAction: nil,
            postponeCount: 0,
            resolvedAt: nil,
            lastDecisionPromptAt: nil,
            strictMode: strictMode,
            streakCount: streakCount,
            lastCheckInDate: nil,
            currentMilestone: 0,
            createdAt: startDate,
            updatedAt: Date()
        )
        return item
    }

    static func sampleCompletion(
        item: DeferItem,
        completedAt: Date,
        outcome: DecisionOutcome = .resisted,
        reflection: String? = nil,
        urgeScore: Int? = nil,
        regretScore: Int? = nil
    ) -> CompletionHistory {
        let days = max(1, Calendar.current.dateComponents([.day], from: item.startDate, to: completedAt).day ?? 1)
        return CompletionHistory(
            deferID: item.id,
            deferTitle: item.title,
            category: item.category,
            type: item.type,
            outcome: outcome,
            protocolType: item.delayProtocolType,
            protocolDurationHours: item.delayDurationHours,
            startDate: item.startDate,
            targetDate: item.targetDate,
            completedAt: completedAt,
            durationDays: days,
            wasAfterCheckpoint: completedAt >= item.targetDate,
            summary: item.whyItMatters,
            reflection: reflection,
            urgeScore: urgeScore,
            regretScore: regretScore,
            estimatedCost: item.estimatedCost,
            createdAt: completedAt,
            deferItem: item
        )
    }

    static func sampleAchievement(key: String, sourceDefer: DeferItem?, unlockedAt: Date = .now) -> Achievement {
        let definition = AchievementCatalog.definition(for: key)
        return Achievement(
            key: key,
            title: definition?.title ?? "Achievement",
            details: definition?.details ?? "Unlocked in preview",
            tier: definition?.tier ?? .bronze,
            unlockedAt: unlockedAt,
            sourceDeferID: sourceDefer?.id,
            createdAt: unlockedAt,
            sourceDefer: sourceDefer
        )
    }

    static func inMemoryContainerWithSeedData() -> ModelContainer {
        let container = DeferModelContainer.makeModelContainer(inMemory: true)
        let context = ModelContext(container)
        let bundle = sampleBundle()

        for item in bundle.allItems {
            context.insert(item)
        }

        for completion in bundle.completions {
            context.insert(completion)
        }

        for urge in bundle.urgeLogs {
            context.insert(urge)
        }

        for achievement in bundle.achievements {
            context.insert(achievement)
        }

        try? context.save()
        return container
    }

    private static func type(for category: DeferCategory) -> DeferType {
        switch category {
        case .spending:
            return .spending
        case .custom:
            return .custom
        default:
            return .abstinence
        }
    }
}
