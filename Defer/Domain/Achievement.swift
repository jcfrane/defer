import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var key: String
    var title: String
    var details: String
    var tier: AchievementTier
    var unlockedAt: Date
    var sourceDeferID: UUID?
    var createdAt: Date

    var sourceDefer: DeferItem?

    init(
        id: UUID = UUID(),
        key: String,
        title: String,
        details: String,
        tier: AchievementTier,
        unlockedAt: Date = .now,
        sourceDeferID: UUID? = nil,
        createdAt: Date = .now,
        sourceDefer: DeferItem? = nil
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.details = details
        self.tier = tier
        self.unlockedAt = unlockedAt
        self.sourceDeferID = sourceDeferID
        self.createdAt = createdAt
        self.sourceDefer = sourceDefer
    }
}
