import Foundation
import SwiftData

@Model
final class RewardLedgerEntry {
    @Attribute(.unique) var id: UUID
    var deferID: UUID
    var points: Int
    var reason: String
    var createdAt: Date

    var deferItem: DeferItem?

    init(
        id: UUID = UUID(),
        deferID: UUID,
        points: Int,
        reason: String,
        createdAt: Date = .now,
        deferItem: DeferItem? = nil
    ) {
        self.id = id
        self.deferID = deferID
        self.points = points
        self.reason = reason
        self.createdAt = createdAt
        self.deferItem = deferItem
    }
}
