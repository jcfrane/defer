import Foundation
import SwiftData

@Model
final class UrgeLog {
    @Attribute(.unique) var id: UUID
    var deferID: UUID
    var loggedAt: Date
    var intensity: Int
    var note: String?
    var usedFallbackAction: Bool
    var createdAt: Date

    var deferItem: DeferItem?

    init(
        id: UUID = UUID(),
        deferID: UUID,
        loggedAt: Date = .now,
        intensity: Int,
        note: String? = nil,
        usedFallbackAction: Bool = false,
        createdAt: Date = .now,
        deferItem: DeferItem? = nil
    ) {
        self.id = id
        self.deferID = deferID
        self.loggedAt = loggedAt
        self.intensity = max(1, min(intensity, 5))
        self.note = note
        self.usedFallbackAction = usedFallbackAction
        self.createdAt = createdAt
        self.deferItem = deferItem
    }
}
