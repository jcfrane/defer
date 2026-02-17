import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    func averageDuration(from completions: [CompletionHistory]) -> Int {
        guard !completions.isEmpty else { return 0 }
        let total = completions.reduce(0) { $0 + $1.durationDays }
        return total / completions.count
    }

    func categoryBreakdown(from completions: [CompletionHistory]) -> [(DeferCategory, Int)] {
        let grouped = Dictionary(grouping: completions, by: \.category)
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
}
