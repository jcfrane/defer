import Foundation
import SwiftData

enum DeferRepositoryError: LocalizedError {
    case invalidDateRange
    case emptyTitle
    case invalidState(String)
    case invalidStatusTransition
    case invalidOutcome
    case checkpointUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "Decision checkpoint must be after capture time."
        case .emptyTitle:
            return "A desire title is required."
        case .invalidState(let detail):
            return detail
        case .invalidStatusTransition:
            return "This status change is not allowed."
        case .invalidOutcome:
            return "This decision outcome is not valid here."
        case .checkpointUnavailable:
            return "No due checkpoint is available for this intent."
        }
    }
}

protocol DeferRepository {
    func captureIntent(
        title: String,
        whyItMatters: String?,
        category: DeferCategory,
        type: DeferType,
        estimatedCost: Double?,
        delayProtocol: DelayProtocol,
        fallbackAction: String?,
        capturedAt: Date
    ) throws -> DeferItem

    func updateIntent(_ intent: DeferItem) throws
    func deleteDefer(_ deferItem: DeferItem) throws

    func refreshLifecycle(asOf date: Date) throws -> Int
    func logUrge(intent: DeferItem, intensity: Int, note: String?, usedFallbackAction: Bool, at date: Date) throws
    func deleteUrgeLog(_ urgeLog: UrgeLog) throws
    func completeDecision(
        intent: DeferItem,
        outcome: DecisionOutcome,
        reflection: String?,
        urgeScore: Int?,
        regretScore: Int?,
        at date: Date
    ) throws
    func postponeDecision(intent: DeferItem, delayProtocol: DelayProtocol, note: String?, at date: Date) throws

    func fetchAllDefers() throws -> [DeferItem]
    func fetchNeedsDecisionNow(from referenceDate: Date) throws -> [DeferItem]
    func fetchInDelayWindow(from referenceDate: Date) throws -> [DeferItem]
    func fetchResolvedDefers() throws -> [DeferItem]
    func fetchRecentUrges(limit: Int) throws -> [UrgeLog]

    // Legacy API maintained for older call sites.
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
    func setStatus(for deferItem: DeferItem, to status: DeferStatus, at date: Date) throws
    func checkIn(deferItem: DeferItem, status: StreakEntryStatus, note: String?, at date: Date) throws
    func recoverLatestStrictFailure(for deferItem: DeferItem, at date: Date) throws -> Bool
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

    func captureIntent(
        title: String,
        whyItMatters: String?,
        category: DeferCategory,
        type: DeferType,
        estimatedCost: Double?,
        delayProtocol: DelayProtocol,
        fallbackAction: String?,
        capturedAt: Date = .now
    ) throws -> DeferItem {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else {
            throw DeferRepositoryError.emptyTitle
        }

        let decisionDate = delayProtocol.decisionDate(from: capturedAt, calendar: calendar)
        guard decisionDate > capturedAt else {
            throw DeferRepositoryError.invalidDateRange
        }

        let intent = DeferItem(
            title: normalizedTitle,
            details: whyItMatters,
            whyItMatters: whyItMatters,
            category: category,
            type: type,
            startDate: capturedAt,
            targetDate: decisionDate,
            status: .activeWait,
            outcome: nil,
            delayProtocolType: delayProtocol.type,
            delayDurationHours: delayProtocol.durationHours,
            estimatedCost: estimatedCost,
            fallbackAction: fallbackAction,
            postponeCount: 0,
            resolvedAt: nil,
            lastDecisionPromptAt: nil,
            strictMode: false,
            streakCount: 0,
            lastCheckInDate: nil,
            currentMilestone: 0,
            createdAt: capturedAt,
            updatedAt: capturedAt
        )

        context.insert(intent)
        try validateMutableState(for: intent)
        try context.save()

        DecisionAnalytics.track(event: DecisionAnalytics.desireCaptured, intent: intent, timestamp: capturedAt)
        DecisionAnalytics.track(
            event: DecisionAnalytics.delayProtocolSelected,
            intent: intent,
            timestamp: capturedAt,
            extras: ["protocol_display": delayProtocol.type.displayName]
        )

        queueSyncOperation(kind: .deferCreated, deferID: intent.id, payload: ["category": intent.category.rawValue])
        return intent
    }

    func updateIntent(_ intent: DeferItem) throws {
        intent.title = intent.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !intent.title.isEmpty else {
            throw DeferRepositoryError.emptyTitle
        }

        intent.whyItMatters = intent.whyItMatters?.trimmingCharacters(in: .whitespacesAndNewlines)
        intent.details = intent.whyItMatters

        try validateMutableState(for: intent)
        intent.updatedAt = .now
        try context.save()
        queueSyncOperation(kind: .deferUpdated, deferID: intent.id)
    }

    func deleteDefer(_ deferItem: DeferItem) throws {
        let deletedID = deferItem.id
        context.delete(deferItem)
        try context.save()
        queueSyncOperation(kind: .deferDeleted, deferID: deletedID)
    }

    func refreshLifecycle(asOf date: Date = .now) throws -> Int {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        let intents = try context.fetch(descriptor)
        var transitioned = 0

        for intent in intents {
            guard intent.status.normalizedLifecycle == .activeWait else { continue }
            guard intent.targetDate <= date else { continue }

            intent.transition(to: .checkpointDue, at: date)
            transitioned += 1

            DecisionAnalytics.track(event: DecisionAnalytics.checkpointDue, intent: intent, timestamp: date)
            queueSyncOperation(
                kind: .deferStatusChanged,
                deferID: intent.id,
                payload: ["from": DeferStatus.activeWait.rawValue, "to": DeferStatus.checkpointDue.rawValue]
            )
        }

        if transitioned > 0 {
            try context.save()
        }

        return transitioned
    }

    func logUrge(
        intent: DeferItem,
        intensity: Int,
        note: String?,
        usedFallbackAction: Bool,
        at date: Date = .now
    ) throws {
        let log = UrgeLog(
            deferID: intent.id,
            loggedAt: date,
            intensity: intensity,
            note: note,
            usedFallbackAction: usedFallbackAction,
            createdAt: date,
            deferItem: intent
        )
        context.insert(log)

        intent.updatedAt = date
        if usedFallbackAction {
            let reward = RewardLedgerEntry(
                deferID: intent.id,
                points: 1,
                reason: "Used fallback action during urge",
                createdAt: date,
                deferItem: intent
            )
            context.insert(reward)
        }

        try context.save()

        DecisionAnalytics.track(
            event: DecisionAnalytics.urgeLogged,
            intent: intent,
            timestamp: date,
            extras: [
                "intensity": "\(max(1, min(intensity, 5)))",
                "used_fallback": usedFallbackAction ? "true" : "false"
            ]
        )

        let unlocked = try achievementEngine.evaluateTriggers(at: date, sourceDefer: intent)
        if !unlocked.isEmpty {
            queueSyncOperation(
                kind: .achievementUnlocked,
                deferID: intent.id,
                payload: ["count": "\(unlocked.count)"]
            )
        }
    }

    func deleteUrgeLog(_ urgeLog: UrgeLog) throws {
        if let deferItem = urgeLog.deferItem {
            deferItem.updatedAt = .now
        }

        context.delete(urgeLog)
        try context.save()
    }

    func completeDecision(
        intent: DeferItem,
        outcome: DecisionOutcome,
        reflection: String?,
        urgeScore: Int?,
        regretScore: Int?,
        at date: Date = .now
    ) throws {
        guard outcome != .postponed else {
            throw DeferRepositoryError.invalidOutcome
        }

        let normalizedStatus = intent.status.normalizedLifecycle
        guard normalizedStatus == .activeWait || normalizedStatus == .checkpointDue else {
            throw DeferRepositoryError.invalidStatusTransition
        }

        let finalStatus: DeferStatus = outcome == .canceled ? .canceled : .resolved
        let previous = intent.status

        intent.outcome = outcome
        intent.resolvedAt = date
        intent.transition(to: finalStatus, at: date)

        let durationDays = max(
            1,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: intent.startDate),
                to: calendar.startOfDay(for: date)
            ).day ?? 1
        )

        let trimmedReflection = reflection?.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = CompletionHistory(
            deferID: intent.id,
            deferTitle: intent.title,
            category: intent.category,
            type: intent.type,
            outcome: outcome,
            protocolType: intent.delayProtocolType,
            protocolDurationHours: intent.delayDurationHours,
            startDate: intent.startDate,
            targetDate: intent.targetDate,
            completedAt: date,
            durationDays: durationDays,
            wasAfterCheckpoint: date >= intent.targetDate,
            summary: intent.whyItMatters,
            reflection: trimmedReflection,
            urgeScore: urgeScore,
            regretScore: regretScore,
            estimatedCost: intent.estimatedCost,
            createdAt: date,
            deferItem: intent
        )
        context.insert(record)

        if let points = pointsForOutcome(outcome), points > 0 {
            let reward = RewardLedgerEntry(
                deferID: intent.id,
                points: points,
                reason: "Decision outcome: \(outcome.rawValue)",
                createdAt: date,
                deferItem: intent
            )
            context.insert(reward)
        }

        try context.save()

        DecisionAnalytics.track(
            event: DecisionAnalytics.decisionRecorded,
            intent: intent,
            timestamp: date,
            extras: [
                "outcome": outcome.rawValue,
                "checkpoint_due": (normalizedStatus == .checkpointDue || date >= intent.targetDate) ? "true" : "false"
            ]
        )

        if let trimmedReflection, !trimmedReflection.isEmpty {
            DecisionAnalytics.track(event: DecisionAnalytics.reflectionSubmitted, intent: intent, timestamp: date)
        }

        queueSyncOperation(
            kind: .deferStatusChanged,
            deferID: intent.id,
            payload: ["from": previous.rawValue, "to": finalStatus.rawValue, "outcome": outcome.rawValue]
        )

        let unlocked = try achievementEngine.evaluateTriggers(at: date, sourceDefer: intent)
        if !unlocked.isEmpty {
            queueSyncOperation(kind: .achievementUnlocked, deferID: intent.id, payload: ["count": "\(unlocked.count)"])
        }
    }

    func postponeDecision(intent: DeferItem, delayProtocol: DelayProtocol, note: String?, at date: Date = .now) throws {
        let normalizedStatus = intent.status.normalizedLifecycle
        guard normalizedStatus == .checkpointDue || normalizedStatus == .activeWait else {
            throw DeferRepositoryError.checkpointUnavailable
        }

        let nextDate = delayProtocol.decisionDate(from: date, calendar: calendar)
        guard nextDate > date else {
            throw DeferRepositoryError.invalidDateRange
        }

        let history = CompletionHistory(
            deferID: intent.id,
            deferTitle: intent.title,
            category: intent.category,
            type: intent.type,
            outcome: .postponed,
            protocolType: intent.delayProtocolType,
            protocolDurationHours: intent.delayDurationHours,
            startDate: intent.startDate,
            targetDate: intent.targetDate,
            completedAt: date,
            durationDays: max(1, calendar.dateComponents([.day], from: intent.startDate, to: date).day ?? 1),
            wasAfterCheckpoint: date >= intent.targetDate,
            summary: note,
            reflection: nil,
            urgeScore: nil,
            regretScore: nil,
            estimatedCost: intent.estimatedCost,
            createdAt: date,
            deferItem: intent
        )
        context.insert(history)

        intent.postponeCount += 1
        intent.delayProtocolType = delayProtocol.type
        intent.delayDurationHours = delayProtocol.durationHours
        intent.targetDate = nextDate
        intent.status = .activeWait
        intent.updatedAt = date

        try context.save()

        DecisionAnalytics.track(
            event: DecisionAnalytics.decisionPostponed,
            intent: intent,
            timestamp: date,
            extras: ["new_protocol": delayProtocol.type.rawValue]
        )

        queueSyncOperation(
            kind: .deferStatusChanged,
            deferID: intent.id,
            payload: ["to": DeferStatus.activeWait.rawValue, "reason": DecisionOutcome.postponed.rawValue]
        )

        let unlocked = try achievementEngine.evaluateTriggers(at: date, sourceDefer: intent)
        if !unlocked.isEmpty {
            queueSyncOperation(kind: .achievementUnlocked, deferID: intent.id, payload: ["count": "\(unlocked.count)"])
        }
    }

    func fetchAllDefers() throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func fetchNeedsDecisionNow(from referenceDate: Date = .now) throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter { item in
            let normalized = item.status.normalizedLifecycle
            return normalized == .checkpointDue || (normalized == .activeWait && item.targetDate <= referenceDate)
        }
    }

    func fetchInDelayWindow(from referenceDate: Date = .now) throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter { item in
            item.status.normalizedLifecycle == .activeWait && item.targetDate > referenceDate
        }
    }

    func fetchResolvedDefers() throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.updatedAt, order: .reverse)])
        return try context.fetch(descriptor).filter { item in
            let normalized = item.status.normalizedLifecycle
            return normalized == .resolved || normalized == .canceled
        }
    }

    func fetchRecentUrges(limit: Int = 12) throws -> [UrgeLog] {
        let descriptor = FetchDescriptor<UrgeLog>(sortBy: [SortDescriptor(\UrgeLog.loggedAt, order: .reverse)])
        let records = try context.fetch(descriptor)
        return Array(records.prefix(max(0, limit)))
    }

    // MARK: - Legacy wrappers

    func createDefer(
        title: String,
        details: String?,
        category: DeferCategory,
        type: DeferType,
        startDate: Date,
        targetDate: Date,
        strictMode: Bool
    ) throws -> DeferItem {
        _ = strictMode
        let protocolType: DelayProtocolType = targetDate.timeIntervalSince(startDate) <= 60 * 60
            ? .tenMinutes
            : .customDate

        return try captureIntent(
            title: title,
            whyItMatters: details,
            category: category,
            type: type,
            estimatedCost: nil,
            delayProtocol: DelayProtocol(type: protocolType, customDate: targetDate),
            fallbackAction: nil,
            capturedAt: startDate
        )
    }

    func updateDefer(_ deferItem: DeferItem) throws {
        try updateIntent(deferItem)
    }

    func setStatus(for deferItem: DeferItem, to status: DeferStatus, at date: Date = .now) throws {
        let normalized = status.normalizedLifecycle

        switch normalized {
        case .activeWait:
            deferItem.transition(to: .activeWait, at: date)
            try context.save()
        case .checkpointDue:
            deferItem.transition(to: .checkpointDue, at: date)
            try context.save()
        case .resolved:
            let outcome: DecisionOutcome
            switch status {
            case .failed:
                outcome = .gaveIn
            case .completed:
                outcome = .resisted
            default:
                outcome = .intentionalYes
            }
            try completeDecision(
                intent: deferItem,
                outcome: outcome,
                reflection: nil,
                urgeScore: nil,
                regretScore: nil,
                at: date
            )
        case .canceled:
            try completeDecision(
                intent: deferItem,
                outcome: .canceled,
                reflection: nil,
                urgeScore: nil,
                regretScore: nil,
                at: date
            )
        default:
            throw DeferRepositoryError.invalidStatusTransition
        }
    }

    func checkIn(deferItem: DeferItem, status: StreakEntryStatus, note: String?, at date: Date = .now) throws {
        switch status {
        case .success:
            deferItem.registerCheckIn(at: date)
            try logUrge(intent: deferItem, intensity: 2, note: note ?? "Quick check-in", usedFallbackAction: false, at: date)
        case .failed:
            try completeDecision(
                intent: deferItem,
                outcome: .gaveIn,
                reflection: note,
                urgeScore: nil,
                regretScore: nil,
                at: date
            )
        case .skipped:
            try logUrge(intent: deferItem, intensity: 3, note: note ?? "Skipped check-in", usedFallbackAction: false, at: date)
        }
    }

    func recoverLatestStrictFailure(for deferItem: DeferItem, at date: Date = .now) throws -> Bool {
        guard deferItem.status.normalizedLifecycle == .resolved,
              deferItem.outcome == .gaveIn else {
            return false
        }

        deferItem.outcome = nil
        deferItem.resolvedAt = nil
        deferItem.transition(to: .activeWait, at: date)
        deferItem.targetDate = max(deferItem.targetDate, date.addingTimeInterval(6 * 60 * 60))

        try context.save()
        return true
    }

    func fetchActiveDefers() throws -> [DeferItem] {
        try fetchInDelayWindow(from: .now)
    }

    func fetchCompletedDefers() throws -> [DeferItem] {
        try fetchResolvedDefers().filter { $0.outcome != .canceled }
    }

    func fetchDueSoonDefers(within days: Int, from referenceDate: Date = .now) throws -> [DeferItem] {
        let lowerBound = calendar.startOfDay(for: referenceDate)
        guard let upperBound = calendar.date(byAdding: .day, value: days, to: lowerBound) else {
            return []
        }

        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter {
            $0.status.normalizedLifecycle == .activeWait && $0.targetDate >= lowerBound && $0.targetDate <= upperBound
        }
    }

    func fetchOverdueDefers(from referenceDate: Date = .now) throws -> [DeferItem] {
        let descriptor = FetchDescriptor<DeferItem>(sortBy: [SortDescriptor(\DeferItem.targetDate)])
        return try context.fetch(descriptor).filter {
            $0.status.normalizedLifecycle == .activeWait && $0.targetDate < referenceDate
        }
    }

    func autoCheckInNonStrictDefers(asOf date: Date = .now) throws -> Int {
        _ = date
        return 0
    }

    func autoCompleteEligibleDefers(asOf date: Date = .now) throws -> Int {
        try refreshLifecycle(asOf: date)
    }

    func enforceStrictModeCheckIn(asOf date: Date = .now) throws {
        _ = try refreshLifecycle(asOf: date)
    }

    // MARK: - Internal helpers

    private func validateMutableState(for intent: DeferItem) throws {
        if intent.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DeferRepositoryError.emptyTitle
        }

        if intent.targetDate <= intent.startDate {
            throw DeferRepositoryError.invalidDateRange
        }

        if intent.delayDurationHours < 0 {
            throw DeferRepositoryError.invalidState("Delay duration cannot be negative.")
        }

        if let estimatedCost = intent.estimatedCost, estimatedCost < 0 {
            throw DeferRepositoryError.invalidState("Estimated cost cannot be negative.")
        }
    }

    private func pointsForOutcome(_ outcome: DecisionOutcome) -> Int? {
        switch outcome {
        case .resisted:
            return 6
        case .intentionalYes:
            return 5
        case .gaveIn:
            return 1
        case .canceled:
            return 0
        case .postponed:
            return nil
        }
    }

    private func queueSyncOperation(
        kind: DeferredSyncOperation.Kind,
        deferID: UUID?,
        payload: [String: String] = [:]
    ) {
        DeferredSyncQueue.enqueue(
            DeferredSyncOperation(
                kind: kind,
                deferID: deferID,
                payload: payload
            )
        )
    }
}
