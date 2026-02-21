import Foundation
import Combine

@MainActor
final class DeferDetailViewModel: ObservableObject {
    @Published var selectedOutcome: DecisionOutcome = .resisted
    @Published var reflection: String = ""
    @Published var postponeProtocolType: DelayProtocolType = .twentyFourHours
    @Published var postponeCustomDate: Date = Date().addingTimeInterval(24 * 60 * 60)
    @Published var postponeNote: String = ""

    func progress(for item: DeferItem) -> Double {
        item.progressPercent()
    }

    func hoursRemaining(for item: DeferItem) -> Int {
        item.hoursRemaining()
    }

    func daysRemaining(for item: DeferItem) -> Int {
        item.daysRemaining()
    }

    func urgeCount(for item: DeferItem) -> Int {
        item.urgeLogs.count
    }

    func fallbackUsageCount(for item: DeferItem) -> Int {
        item.urgeLogs.filter(\.usedFallbackAction).count
    }

    func averageUrgeIntensity(for item: DeferItem) -> Double {
        guard !item.urgeLogs.isEmpty else { return 0 }
        let total = item.urgeLogs.reduce(0) { $0 + $1.intensity }
        return Double(total) / Double(item.urgeLogs.count)
    }

    func recentUrges(for item: DeferItem, limit: Int = 6) -> [UrgeLog] {
        Array(item.urgeLogs.sorted(by: { $0.loggedAt > $1.loggedAt }).prefix(max(0, limit)))
    }

    func isLogUrgeDisabled(for item: DeferItem) -> Bool {
        item.status.normalizedLifecycle.isTerminal
    }

    func isDecisionDisabled(for item: DeferItem) -> Bool {
        item.status.normalizedLifecycle.isTerminal
    }

    func postponeProtocol() -> DelayProtocol {
        if postponeProtocolType == .customDate {
            return DelayProtocol(type: .customDate, customDate: postponeCustomDate)
        }

        return DelayProtocol(type: postponeProtocolType)
    }

    func clearDraftInputs() {
        reflection = ""
        postponeNote = ""
    }
}
