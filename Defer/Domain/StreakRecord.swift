import Foundation
import SwiftData

@Model
final class StreakRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var status: StreakEntryStatus
    var note: String?
    var createdAt: Date

    var deferItem: DeferItem?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        status: StreakEntryStatus,
        note: String? = nil,
        createdAt: Date = .now,
        deferItem: DeferItem? = nil
    ) {
        self.id = id
        self.date = date
        self.status = status
        self.note = note
        self.createdAt = createdAt
        self.deferItem = deferItem
    }
}
