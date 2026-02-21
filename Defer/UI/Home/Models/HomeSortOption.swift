import Foundation

enum HomeSortOption: String, CaseIterable, Identifiable {
    case checkpointSoonest = "Soonest"
    case highestUrgency = "Most Urgent"
    case newest = "Newest"

    var id: String { rawValue }
}
