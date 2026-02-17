import Foundation
import Combine

@MainActor
final class DeferFormViewModel: ObservableObject {
    @Published var title: String
    @Published var details: String
    @Published var category: DeferCategory
    @Published var startDate: Date
    @Published var targetDate: Date
    @Published var strictMode: Bool

    init(initialDraft: DeferDraft) {
        self.title = initialDraft.title
        self.details = initialDraft.details
        self.category = initialDraft.category
        self.startDate = initialDraft.startDate
        self.targetDate = initialDraft.targetDate
        self.strictMode = initialDraft.strictMode
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDetails: String {
        details.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !normalizedTitle.isEmpty && targetDate > startDate
    }

    var isDateRangeInvalid: Bool {
        targetDate <= startDate
    }

    func makeDraft() -> DeferDraft {
        DeferDraft(
            title: normalizedTitle,
            details: normalizedDetails,
            category: category,
            startDate: startDate,
            targetDate: targetDate,
            strictMode: strictMode
        )
    }
}
