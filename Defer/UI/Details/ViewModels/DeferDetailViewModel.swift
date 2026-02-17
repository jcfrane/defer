import Foundation
import Combine

@MainActor
final class DeferDetailViewModel: ObservableObject {
    func progress(for item: DeferItem) -> Double {
        item.progressPercent()
    }

    func daysRemaining(for item: DeferItem) -> Int {
        item.daysRemaining()
    }

    func checkInCount(for item: DeferItem) -> Int {
        item.streakRecords.filter { $0.status == .success }.count
    }

    func pauseCount(for item: DeferItem) -> Int {
        item.streakRecords.filter { $0.status == .skipped }.count
    }

    func failCount(for item: DeferItem) -> Int {
        item.streakRecords.filter { $0.status == .failed }.count
    }

    func isCheckInDisabled(for item: DeferItem) -> Bool {
        item.hasCheckedIn() || item.status != .active
    }

    func isPauseDisabled(for item: DeferItem) -> Bool {
        item.status.isTerminal
    }

    func isFailDisabled(for item: DeferItem) -> Bool {
        item.status.isTerminal
    }
}
