import Foundation
import SwiftData

@Model
final class DeferItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var details: String?
    var whyItMatters: String?
    var category: DeferCategory
    var type: DeferType
    var startDate: Date
    var targetDate: Date
    var status: DeferStatus
    var outcome: DecisionOutcome?
    var delayProtocolType: DelayProtocolType
    var delayDurationHours: Int
    var estimatedCost: Double?
    var fallbackAction: String?
    var postponeCount: Int
    var resolvedAt: Date?
    var lastDecisionPromptAt: Date?

    // Legacy fields kept to avoid breaking older tooling and exports.
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

    @Relationship(deleteRule: .cascade, inverse: \UrgeLog.deferItem)
    var urgeLogs: [UrgeLog]

    @Relationship(deleteRule: .cascade, inverse: \RewardLedgerEntry.deferItem)
    var rewardLedgerEntries: [RewardLedgerEntry]

    init(
        id: UUID = UUID(),
        title: String,
        details: String? = nil,
        whyItMatters: String? = nil,
        category: DeferCategory,
        type: DeferType,
        startDate: Date = .now,
        targetDate: Date,
        status: DeferStatus = .activeWait,
        outcome: DecisionOutcome? = nil,
        delayProtocolType: DelayProtocolType = .twentyFourHours,
        delayDurationHours: Int = 24,
        estimatedCost: Double? = nil,
        fallbackAction: String? = nil,
        postponeCount: Int = 0,
        resolvedAt: Date? = nil,
        lastDecisionPromptAt: Date? = nil,
        strictMode: Bool = false,
        streakCount: Int = 0,
        lastCheckInDate: Date? = nil,
        currentMilestone: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.whyItMatters = whyItMatters ?? details
        self.category = category
        self.type = type
        self.startDate = startDate
        self.targetDate = targetDate
        self.status = status
        self.outcome = outcome
        self.delayProtocolType = delayProtocolType
        self.delayDurationHours = delayDurationHours
        self.estimatedCost = estimatedCost
        self.fallbackAction = fallbackAction
        self.postponeCount = postponeCount
        self.resolvedAt = resolvedAt
        self.lastDecisionPromptAt = lastDecisionPromptAt

        self.strictMode = strictMode
        self.streakCount = streakCount
        self.lastCheckInDate = lastCheckInDate
        self.currentMilestone = currentMilestone

        self.createdAt = createdAt
        self.updatedAt = updatedAt

        self.streakRecords = []
        self.completionHistories = []
        self.achievements = []
        self.urgeLogs = []
        self.rewardLedgerEntries = []
    }
}

extension DeferItem {
    var decisionNotBefore: Date {
        get { targetDate }
        set { targetDate = newValue }
    }

    var normalizedStatus: DeferStatus {
        status.normalizedLifecycle
    }

    func daysRemaining(from now: Date = .now, calendar: Calendar = .current) -> Int {
        let startOfNow = calendar.startOfDay(for: now)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: startOfNow, to: startOfTarget).day ?? 0
    }

    func hoursRemaining(from now: Date = .now) -> Int {
        max(0, Int(targetDate.timeIntervalSince(now) / 3600.0))
    }

    func progressPercent(from now: Date = .now) -> Double {
        let totalDuration = targetDate.timeIntervalSince(startDate)
        guard totalDuration > 0 else { return 1.0 }

        let elapsed = now.timeIntervalSince(startDate)
        let rawProgress = elapsed / totalDuration
        return min(max(rawProgress, 0), 1)
    }

    func isCheckpointDue(referenceDate: Date = .now) -> Bool {
        normalizedStatus == .checkpointDue || (
            normalizedStatus == .activeWait && targetDate <= referenceDate
        )
    }

    func hasResolvedIntentionalOutcome() -> Bool {
        guard let outcome else { return false }
        return outcome.isIntentional
    }

    func isCompletedToday(referenceDate: Date = .now, calendar: Calendar = .current) -> Bool {
        guard normalizedStatus == .resolved else { return false }
        guard let latestDecision = completionHistories.max(by: { $0.completedAt < $1.completedAt }) else {
            return false
        }

        return calendar.isDate(latestDecision.completedAt, inSameDayAs: referenceDate)
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
