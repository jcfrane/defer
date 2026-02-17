import Foundation
import SwiftData

struct PreviewFixtureBundle {
    let activeItems: [DeferItem]
    let archivedItems: [DeferItem]
    let completions: [CompletionHistory]
    let achievements: [Achievement]

    var allItems: [DeferItem] {
        activeItems + archivedItems
    }
}

enum PreviewFixtures {
    static func sampleBundle(now: Date = .now) -> PreviewFixtureBundle {
        let calendar = Calendar.current

        let activeOne = sampleDefer(
            title: "No Sugar Weekdays",
            details: "Keep weekdays clean and track cravings.",
            category: .nutrition,
            status: .active,
            strictMode: true,
            streakCount: 6,
            startDate: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: 18, to: now) ?? now
        )

        let activeTwo = sampleDefer(
            title: "No Impulse Purchases",
            details: "Wait 24 hours before spending.",
            category: .spending,
            status: .paused,
            strictMode: false,
            streakCount: 12,
            startDate: calendar.date(byAdding: .day, value: -20, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: 10, to: now) ?? now
        )

        let activeThree = sampleDefer(
            title: "Morning Workout",
            details: "30-minute sessions before 8 AM.",
            category: .health,
            status: .active,
            strictMode: true,
            streakCount: 4,
            startDate: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: 25, to: now) ?? now
        )

        let completed = sampleDefer(
            title: "No Late-Night Snacking",
            details: "Cut snacks after 9 PM.",
            category: .habit,
            status: .completed,
            strictMode: true,
            streakCount: 14,
            startDate: calendar.date(byAdding: .day, value: -35, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: -5, to: now) ?? now
        )

        let failed = sampleDefer(
            title: "Daily Journaling",
            details: "10 minutes every evening.",
            category: .productivity,
            status: .failed,
            strictMode: true,
            streakCount: 3,
            startDate: calendar.date(byAdding: .day, value: -15, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: 30, to: now) ?? now
        )

        let completedTwo = sampleDefer(
            title: "No Social Media After 9PM",
            details: "Phone off by 9 PM daily.",
            category: .habit,
            status: .completed,
            strictMode: false,
            streakCount: 9,
            startDate: calendar.date(byAdding: .day, value: -22, to: now) ?? now,
            targetDate: calendar.date(byAdding: .day, value: -2, to: now) ?? now
        )

        activeOne.streakRecords = [
            StreakRecord(
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                status: .success,
                note: nil,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                deferItem: activeOne
            ),
            StreakRecord(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                status: .success,
                note: nil,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                deferItem: activeOne
            )
        ]
        activeOne.lastCheckInDate = calendar.date(byAdding: .day, value: -1, to: now)

        activeTwo.streakRecords = [
            StreakRecord(
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                status: .skipped,
                note: "Paused",
                createdAt: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                deferItem: activeTwo
            )
        ]

        activeThree.streakRecords = [
            StreakRecord(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                status: .success,
                note: nil,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                deferItem: activeThree
            )
        ]
        activeThree.lastCheckInDate = calendar.date(byAdding: .day, value: -1, to: now)

        failed.streakRecords = [
            StreakRecord(
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                status: .failed,
                note: "Missed strict mode check-in.",
                createdAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                deferItem: failed
            )
        ]

        let completions = [
            sampleCompletion(
                item: completed,
                completedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now
            ),
            sampleCompletion(
                item: completedTwo,
                completedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now
            )
        ]

        let achievements = [
            sampleAchievement(key: "first_completion", sourceDefer: completed, unlockedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now),
            sampleAchievement(key: "streak_7", sourceDefer: activeTwo, unlockedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now)
        ]

        return PreviewFixtureBundle(
            activeItems: [activeOne, activeTwo, activeThree],
            archivedItems: [completed, completedTwo, failed],
            completions: completions,
            achievements: achievements
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
        targetDate: Date
    ) -> DeferItem {
        let item = DeferItem(
            title: title,
            details: details,
            category: category,
            type: type(for: category),
            startDate: startDate,
            targetDate: targetDate,
            status: status,
            strictMode: strictMode,
            streakCount: streakCount,
            lastCheckInDate: nil,
            currentMilestone: 0,
            createdAt: startDate,
            updatedAt: Date()
        )
        return item
    }

    static func sampleCompletion(item: DeferItem, completedAt: Date) -> CompletionHistory {
        let days = max(1, Calendar.current.dateComponents([.day], from: item.startDate, to: completedAt).day ?? 1)
        return CompletionHistory(
            deferID: item.id,
            deferTitle: item.title,
            category: item.category,
            type: item.type,
            startDate: item.startDate,
            targetDate: item.targetDate,
            completedAt: completedAt,
            durationDays: days,
            summary: item.details,
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
