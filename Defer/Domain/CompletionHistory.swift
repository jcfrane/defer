import Foundation
import SwiftData

@Model
final class CompletionHistory {
    @Attribute(.unique) var id: UUID
    var deferID: UUID
    var deferTitle: String
    var category: DeferCategory
    var type: DeferType
    var startDate: Date
    var targetDate: Date
    var completedAt: Date
    var durationDays: Int
    var summary: String?
    var createdAt: Date

    var deferItem: DeferItem?

    init(
        id: UUID = UUID(),
        deferID: UUID,
        deferTitle: String,
        category: DeferCategory,
        type: DeferType,
        startDate: Date,
        targetDate: Date,
        completedAt: Date,
        durationDays: Int,
        summary: String? = nil,
        createdAt: Date = .now,
        deferItem: DeferItem? = nil
    ) {
        self.id = id
        self.deferID = deferID
        self.deferTitle = deferTitle
        self.category = category
        self.type = type
        self.startDate = startDate
        self.targetDate = targetDate
        self.completedAt = completedAt
        self.durationDays = durationDays
        self.summary = summary
        self.createdAt = createdAt
        self.deferItem = deferItem
    }
}
