import Foundation

struct HomeStats {
    let activeWait: Int
    let checkpointDue: Int
    let recentUrges: Int
    let intentionalRate: Double
    let delayAdherenceRate: Double
    let reflectionRate: Double

    static func make(
        from defers: [DeferItem],
        decisions: [CompletionHistory],
        urgeLogs: [UrgeLog]
    ) -> HomeStats {
        let activeWait = defers.filter { $0.status.normalizedLifecycle == .activeWait }.count
        let checkpointDue = defers.filter {
            $0.status.normalizedLifecycle == .checkpointDue ||
            ($0.status.normalizedLifecycle == .activeWait && $0.targetDate <= .now)
        }.count

        let resolved = decisions.filter {
            $0.outcome != .postponed && $0.outcome != .canceled
        }

        let intentionalCount = resolved.filter { $0.outcome.isIntentional }.count
        let intentionalRate = resolved.isEmpty ? 0 : Double(intentionalCount) / Double(resolved.count)
        let adherenceRate = resolved.isEmpty ? 0 : Double(resolved.filter(\.wasAfterCheckpoint).count) / Double(resolved.count)
        let reflectionRate = resolved.isEmpty
            ? 0
            : Double(resolved.filter { !($0.reflection?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) }.count) / Double(resolved.count)

        let recentUrges = urgeLogs.filter { $0.loggedAt >= Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast }.count

        return HomeStats(
            activeWait: activeWait,
            checkpointDue: checkpointDue,
            recentUrges: recentUrges,
            intentionalRate: intentionalRate,
            delayAdherenceRate: adherenceRate,
            reflectionRate: reflectionRate
        )
    }
}
