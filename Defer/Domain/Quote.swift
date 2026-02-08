import Foundation
import SwiftData

@Model
final class Quote {
    @Attribute(.unique) var id: UUID
    var text: String
    var author: String?
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        text: String,
        author: String? = nil,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
