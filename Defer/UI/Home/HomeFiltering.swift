import Foundation

enum HomeFiltering {
    static func activeAndOngoing(
        from allDefers: [DeferItem],
        selectedCategory: DeferCategory?,
        sortOption: HomeSortOption
    ) -> [DeferItem] {
        var items = allDefers.filter { $0.status != .completed && $0.status != .canceled }

        if let selectedCategory {
            items = items.filter { $0.category == selectedCategory }
        }

        switch sortOption {
        case .closestDate:
            items.sort { $0.targetDate < $1.targetDate }
        case .longestStreak:
            items.sort { lhs, rhs in
                if lhs.streakCount == rhs.streakCount {
                    return lhs.targetDate < rhs.targetDate
                }
                return lhs.streakCount > rhs.streakCount
            }
        case .newest:
            items.sort { $0.createdAt > $1.createdAt }
        }

        return items
    }
}
