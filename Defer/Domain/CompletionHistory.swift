import Foundation
import SwiftData

@Model
final class CompletionHistory {
    @Attribute(.unique) var id: UUID
    var deferID: UUID
    var deferTitle: String
    var category: DeferCategory
    var type: DeferType
    var outcome: DecisionOutcome
    var protocolType: DelayProtocolType
    var protocolDurationHours: Int
    var startDate: Date
    var targetDate: Date
    var completedAt: Date
    var durationDays: Int
    var wasAfterCheckpoint: Bool
    var summary: String?
    var reflection: String?
    var urgeScore: Int?
    var regretScore: Int?
    var estimatedCost: Double?
    var createdAt: Date

    var deferItem: DeferItem?

    init(
        id: UUID = UUID(),
        deferID: UUID,
        deferTitle: String,
        category: DeferCategory,
        type: DeferType,
        outcome: DecisionOutcome = .resisted,
        protocolType: DelayProtocolType = .twentyFourHours,
        protocolDurationHours: Int = 24,
        startDate: Date,
        targetDate: Date,
        completedAt: Date,
        durationDays: Int,
        wasAfterCheckpoint: Bool = true,
        summary: String? = nil,
        reflection: String? = nil,
        urgeScore: Int? = nil,
        regretScore: Int? = nil,
        estimatedCost: Double? = nil,
        createdAt: Date = .now,
        deferItem: DeferItem? = nil
    ) {
        self.id = id
        self.deferID = deferID
        self.deferTitle = deferTitle
        self.category = category
        self.type = type
        self.outcome = outcome
        self.protocolType = protocolType
        self.protocolDurationHours = protocolDurationHours
        self.startDate = startDate
        self.targetDate = targetDate
        self.completedAt = completedAt
        self.durationDays = durationDays
        self.wasAfterCheckpoint = wasAfterCheckpoint
        self.summary = summary
        self.reflection = reflection
        self.urgeScore = urgeScore
        self.regretScore = regretScore
        self.estimatedCost = estimatedCost
        self.createdAt = createdAt
        self.deferItem = deferItem
    }
}
