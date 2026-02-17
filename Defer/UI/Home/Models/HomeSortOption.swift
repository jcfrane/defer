import Foundation

enum HomeSortOption: String, CaseIterable, Identifiable {
    case closestDate = "Closest Date"
    case longestStreak = "Longest Streak"
    case newest = "Newest"

    var id: String { rawValue }
}
