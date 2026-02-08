import Foundation
import SwiftData

@Model
final class DeferItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String?
    var category: DeferCategory
    var type: DeferType
    var startDate: Date
    var targetDate: Date
    var status: DeferStatus
    var strictMode: Bool
    var streakCount: Int
    var lastCheckInDate: Date?
    var currentMilestone: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StreakRecord.deferItem)
    var streakRecords: [StreakRecord]

    @Relationship(deleteRule: .nullify, inverse: \CompletionHistory.deferItem)
    var completionHistories: [CompletionHistory]

    @Relationship(deleteRule: .nullify, inverse: \Achievement.sourceDefer)
    var achievements: [Achievement]

    init(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        category: DeferCategory,
        type: DeferType,
        startDate: Date = .now,
        targetDate: Date,
        status: DeferStatus = .active,
        strictMode: Bool = true,
        streakCount: Int = 0,
        lastCheckInDate: Date? = nil,
        currentMilestone: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.category = category
        self.type = type
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.strictMode = strictMode
        self.streakCount = streakCount
        self.lastCheckInDate = lastCheckInDate
        self.currentMilestone = currentMilestone
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        self.streakRecords = []
        self.completionHistories = []
        self.achievements = []
    }
}

extension DeferItem {
    func daysRemaining(from now: Date = .now, calendar: Calendar = .current) -> Int {
        let startOfNow = calendar.startOfDay(for: now)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: startOfNow, to: startOfTarget).day ?? 0
    }

    func progressPercent(from now: Date = .now) -> Double {
        let totalDuration = targetDate.timeIntervalSince(startDate)
        guard totalDuration > 0 else { return 1.0 }

        let elapsed = now.timeIntervalSince(startDate)
        let rawProgress = elapsed / totalDuration
        return min(max(rawProgress, 0), 1)
    }

    func isCompletedToday(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard status == .completed else { return false }
        guard let latestCompletion = completionHistories.max(by: { $0.completedAt < $1.completedAt }) else {
            return false
        }

        return calendar.isDate(latestCompletion.completedAt, inSameDayAs: referenceDate)
    }

    func transition(to status: DeferStatus, at date: Date = .now) {
        self.status = status
        self.updatedAt = date
    }

    func registerCheckIn(at date: Date = .now) {
        self.lastCheckInDate = date
        self.streakCount += 1
        self.updatedAt = date
    }

    func hasCheckedIn(on date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let lastCheckInDate else { return false }
        return calendar.isDate(lastCheckInDate, inSameDayAs: date)
    }
}
