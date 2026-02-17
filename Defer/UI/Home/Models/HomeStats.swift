import Foundation

struct HomeStats {
    let active: Int
    let longestStreak: Int
    let dueSoon: Int

    static func make(from defers: [DeferItem]) -> HomeStats {
        let active = defers.filter { $0.status == .active }.count
        let longestStreak = defers.map(\.streakCount).max() ?? 0
        let dueSoon = defers.filter {
            $0.status == .active && $0.daysRemaining() >= 0 && $0.daysRemaining() <= 3
        }.count

        return HomeStats(active: active, longestStreak: longestStreak, dueSoon: dueSoon)
    }
}
