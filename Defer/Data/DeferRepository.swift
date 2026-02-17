import Foundation
import SwiftData

enum DeferRepositoryError: LocalizedError {
    case invalidDateRange
    case duplicateCheckInToday

    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "Target date must be after start date."
        case .duplicateCheckInToday:
            return "You already checked in for this defer today."
        }
    }
}

protocol DeferRepository {
    func createDefer(
        title: String,
        details: String?,
        category: DeferCategory,
        type: DeferType,
        startDate: Date,
        targetDate: Date,
        strictMode: Bool
    ) throws -> DeferItem

    func updateDefer(_ deferItem: DeferItem) throws
    func deleteDefer(_ deferItem: DeferItem) throws

    func setStatus(for deferItem: DeferItem, to status: DeferStatus, at date: Date) throws
    func checkIn(deferItem: DeferItem, status: StreakEntryStatus, note: String?, at date: Date) throws

    func fetchAllDefers() throws -> [DeferItem]
    func fetchActiveDefers() throws -> [DeferItem]
    func fetchCompletedDefers() throws -> [DeferItem]
    func fetchDueSoonDefers(within days: Int, from referenceDate: Date) throws -> [DeferItem]
    func fetchOverdueDefers(from referenceDate: Date) throws -> [DeferItem]
    func autoCheckInNonStrictDefers(asOf date: Date) throws -> Int
    func autoCompleteEligibleDefers(asOf date: Date) throws -> Int
    func enforceStrictModeCheckIn(asOf date: Date) throws
}

final class SwiftDataDeferRepository: DeferRepository {
    private let context: ModelContext
    private let calendar: Calendar
    private lazy var achievementEngine = AchievementEngine(context: context)

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func createDefer(
        title: String,
        details: String?,
        category: DeferCategory,
        type: DeferType,
        startDate: Date,
        targetDate: Date,
        strictMode: Bool
    ) throws -> DeferItem {
        guard targetDate > startDate else {
            throw DeferRepositoryError.invalidDateRange
        }

        let deferItem = DeferItem(
            title: title,
            details: details,
            category: category,
            type: type,
            startDate: startDate,
            targetDate: targetDate,
            status: .active,
            strictMode: strictMode,
            streakCount: 0,
            currentMilestone: 0,
            createdAt: .now,
            updatedAt: .now
        )

        context.insert(deferItem)
        try context.save()
        return deferItem
    }

    func updateDefer(_ deferItem: DeferItem) throws {
        deferItem.updatedAt = .now
        try context.save()
    }

    func deleteDefer(_ deferItem: DeferItem) throws {
        context.delete(deferItem)
        try context.save()
    }

    func setStatus(for deferItem: DeferItem, to status: DeferStatus, at date: Date = .now) throws {
        let previousStatus = deferItem.status
        deferItem.transition(to: status, at: date)

        if status == .paused && previousStatus != .paused {
            insertStreakRecordIfNeeded(
                for: deferItem,
                status: .skipped,
                note: "Paused",
                at: date
            )
        }

        if status == .failed && previousStatus != .failed {
            insertStreakRecordIfNeeded(
                for: deferItem,
                status: .failed,
                note: "Failed",
                at: date
            )
        }

        if status == .completed && previousStatus != .completed {
            let durationDays = max(
                1,
                calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: deferItem.startDate),
                    to: calendar.startOfDay(for: date)
                ).day ?? 1
            )

            let history = CompletionHistory(
                deferID: deferItem.id,
                deferTitle: deferItem.title,
                category: deferItem.category,
                type: deferItem.type,
                startDate: deferItem.startDate,
                targetDate: deferItem.targetDate,
                completedAt: date,
                durationDays: durationDays,
                summary: deferItem.details,
                createdAt: date,
                deferItem: deferItem
            )
            context.insert(history)
        }

        try context.save()

        if status == .completed && previousStatus != .completed {
            _ = try achievementEngine.evaluateTriggers(at: date, sourceDefer: deferItem)
        }
    }

    func checkIn(deferItem: DeferItem, status: StreakEntryStatus, note: String?, at date: Date = .now) throws {
        if deferItem.hasCheckedIn(on: date, calendar: calendar) {
            throw DeferRepositoryError.duplicateCheckInToday
        }

        insertStreakRecordIfNeeded(
            for: deferItem,
            status: status,
            note: note,
            at: date
        )

        if status == .success {
            deferItem.registerCheckIn(at: date)
        } else if status == .failed {
            if deferItem.strictMode {
                deferItem.transition(to: .failed, at: date)
            } else {
                // In non-strict mode, failed check-ins are informational only.
                deferItem.updatedAt = date
            }
        } else {
            deferItem.updatedAt = date
        }

        try context.save()

        if status == .success {
            _ = try achievementEngine.evaluateTriggers(at: date, sourceDefer: deferItem)
        }
    }

    func fetchAllDefers() throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor)
    }

    func fetchActiveDefers() throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter { $0.status == .active }
    }

    func fetchCompletedDefers() throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.updatedAt, order: .reverse)])
        return try context.fetch(descriptor).filter { $0.status == .completed }
    }

    func fetchDueSoonDefers(within days: Int, from referenceDate: Date = .now) throws -> [DeferItem] {
        let lowerBound = calendar.startOfDay(for: referenceDate)
        guard let upperBound = calendar.date(byAdding: .day, value: days, to: lowerBound) else {
            return []
        }

        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter {
            $0.status == .active && $0.targetDate >= lowerBound && $0.targetDate <= upperBound
        }
    }

    func fetchOverdueDefers(from referenceDate: Date = .now) throws -> [DeferItem] {
        let today = calendar.startOfDay(for: referenceDate)

        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter {
            $0.status == .active && $0.targetDate < today
        }
    }

    func autoCheckInNonStrictDefers(asOf date: Date = .now) throws -> Int {
        let dayStart = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        let nonStrictDefers = try context.fetch(descriptor).filter {
            $0.status == .active &&
            !$0.strictMode &&
            calendar.startOfDay(for: $0.startDate) <= dayStart
        }

        guard
            let previousDay = calendar.date(byAdding: .day, value: -1, to: dayStart)
        else {
            return 0
        }

        var insertedCount = 0

        for deferItem in nonStrictDefers {
            let startDay = calendar.startOfDay(for: deferItem.startDate)
            let targetDay = calendar.startOfDay(for: deferItem.targetDate)
            let upperBound = min(previousDay, targetDay)
            guard startDay <= upperBound else { continue }

            var cursor = nextAutoCheckInDay(for: deferItem, minimum: startDay)
            while cursor <= upperBound {
                let inserted = insertStreakRecordIfNeeded(
                    for: deferItem,
                    status: .success,
                    note: nil,
                    at: cursor
                )
                if inserted {
                    deferItem.registerCheckIn(at: cursor)
                    insertedCount += 1
                }

                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                    break
                }
                cursor = nextDay
            }
        }

        if context.hasChanges {
            try context.save()
        }

        return insertedCount
    }

    func autoCompleteEligibleDefers(asOf date: Date = .now) throws -> Int {
        let dayStart = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        let eligible = try context.fetch(descriptor).filter {
            $0.status == .active && $0.targetDate < dayStart
        }
        for deferItem in eligible {
            try setStatus(for: deferItem, to: .completed, at: date)
        }
        return eligible.count
    }

    func enforceStrictModeCheckIn(asOf date: Date = .now) throws {
        let dayStart = calendar.startOfDay(for: date)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: dayStart) else {
            return
        }

        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        let strictDefers = try context.fetch(descriptor).filter {
            $0.status == .active &&
            $0.strictMode &&
            calendar.startOfDay(for: $0.startDate) <= yesterday &&
            $0.targetDate >= dayStart
        }

        for deferItem in strictDefers {
            guard let lastCheckIn = deferItem.lastCheckInDate else {
                try setStatus(for: deferItem, to: .failed, at: date)
                continue
            }

            let lastCheckInDay = calendar.startOfDay(for: lastCheckIn)
            if lastCheckInDay < yesterday {
                try setStatus(for: deferItem, to: .failed, at: date)
            }
        }

        if context.hasChanges {
            try context.save()
        }
    }

    private func insertStreakRecordIfNeeded(
        for deferItem: DeferItem,
        status: StreakEntryStatus,
        note: String?,
        at date: Date
    ) -> Bool {
        let day = calendar.startOfDay(for: date)
        let alreadyExists = deferItem.streakRecords.contains {
            $0.status == status && calendar.isDate($0.date, inSameDayAs: day)
        }

        guard !alreadyExists else { return false }

        let record = StreakRecord(
            date: date,
            status: status,
            note: note,
            createdAt: date,
            deferItem: deferItem
        )
        context.insert(record)
        return true
    }

    private func nextAutoCheckInDay(for deferItem: DeferItem, minimum: Date) -> Date {
        let latestSuccessDay = deferItem.streakRecords
            .filter { $0.status == .success }
            .map { calendar.startOfDay(for: $0.date) }
            .max()

        let latestKnownDay = [
            deferItem.lastCheckInDate.map { calendar.startOfDay(for: $0) },
            latestSuccessDay
        ]
        .compactMap { $0 }
        .max()

        guard
            let latestKnownDay,
            let nextDay = calendar.date(byAdding: .day, value: 1, to: latestKnownDay)
        else {
            return minimum
        }

        return max(minimum, nextDay)
    }
}
