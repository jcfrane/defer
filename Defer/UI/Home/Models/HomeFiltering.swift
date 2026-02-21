import Foundation

enum HomeFiltering {
    static func pendingIntents(
        from allDefers: [DeferItem],
        selectedCategory: DeferCategory?,
        sortOption: HomeSortOption,
        referenceDate: Date = .now
    ) -> [DeferItem] {
        var items = allDefers.filter {
            let normalized = $0.status.normalizedLifecycle
            return normalized == .activeWait || normalized == .checkpointDue
        }

        if let selectedCategory {
            items = items.filter { $0.category == selectedCategory }
        }

        switch sortOption {
        case .checkpointSoonest:
            items.sort { lhs, rhs in
                let lhsDue = lhs.isCheckpointDue(referenceDate: referenceDate)
                let rhsDue = rhs.isCheckpointDue(referenceDate: referenceDate)
                if lhsDue != rhsDue {
                    return lhsDue && !rhsDue
                }
                return lhs.targetDate < rhs.targetDate
            }
        case .highestUrgency:
            items.sort { lhs, rhs in
                let lhsUrgency = urgencyScore(for: lhs, now: referenceDate)
                let rhsUrgency = urgencyScore(for: rhs, now: referenceDate)
                if lhsUrgency == rhsUrgency {
                    return lhs.targetDate < rhs.targetDate
                }
                return lhsUrgency > rhsUrgency
            }
        case .newest:
            items.sort { $0.createdAt > $1.createdAt }
        }

        return items
    }

    private static func urgencyScore(for item: DeferItem, now: Date) -> Double {
        if item.isCheckpointDue(referenceDate: now) {
            return 1000
        }

        let hoursLeft = max(1, item.hoursRemaining(from: now))
        let urgeBias = Double(item.urgeLogs.suffix(3).reduce(0) { $0 + $1.intensity })
        return (100.0 / Double(hoursLeft)) + urgeBias
    }
}
