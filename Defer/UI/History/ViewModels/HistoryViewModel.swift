import Foundation
import Combine

struct HistorySummaryMetrics {
    let decisionCount: Int
    let intentionalRate: Double
    let delayAdherenceRate: Double
    let reflectionRate: Double
    let impulseSpendAvoided: Double
    let averageRegretDelta: Double?
    let latestDecisionDate: Date?
    let earliestDecisionDate: Date?
}

struct HistoryCategoryStat: Identifiable {
    let category: DeferCategory
    let count: Int
    let share: Double
    let intentionalShare: Double

    var id: DeferCategory { category }
}

struct HistoryMonthStat: Identifiable {
    let monthStart: Date
    let count: Int
    let intentionalRate: Double
    let relativeIntensity: Double

    var id: Date { monthStart }
}

struct HistoryTimelineGroup: Identifiable {
    let monthStart: Date
    let decisions: [CompletionHistory]

    var id: Date { monthStart }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    func summaryMetrics(
        from decisions: [CompletionHistory],
        calendar: Calendar = .current
    ) -> HistorySummaryMetrics {
        guard !decisions.isEmpty else {
            return HistorySummaryMetrics(
                decisionCount: 0,
                intentionalRate: 0,
                delayAdherenceRate: 0,
                reflectionRate: 0,
                impulseSpendAvoided: 0,
                averageRegretDelta: nil,
                latestDecisionDate: nil,
                earliestDecisionDate: nil
            )
        }

        let resolved = decisions.filter {
            $0.outcome != .postponed && $0.outcome != .canceled
        }

        let intentionalCount = resolved.filter { $0.outcome.isIntentional }.count
        let intentionalRate = resolved.isEmpty ? 0 : Double(intentionalCount) / Double(resolved.count)
        let adherenceRate = resolved.isEmpty ? 0 : Double(resolved.filter(\.wasAfterCheckpoint).count) / Double(resolved.count)
        let reflectionRate = resolved.isEmpty ? 0 : Double(resolved.filter { !($0.reflection?.isEmpty ?? true) }.count) / Double(resolved.count)

        let impulseSpendAvoided = decisions
            .filter { $0.outcome == .resisted }
            .reduce(0) { $0 + ($1.estimatedCost ?? 0) }

        let regretSamples = resolved.compactMap { record -> Double? in
            guard let urge = record.urgeScore, let regret = record.regretScore else { return nil }
            return Double(regret - urge)
        }

        let averageRegretDelta = regretSamples.isEmpty
            ? nil
            : regretSamples.reduce(0, +) / Double(regretSamples.count)

        let latestDecisionDate = decisions.map(\.completedAt).max()
        let earliestDecisionDate = decisions.map(\.completedAt).min()

        return HistorySummaryMetrics(
            decisionCount: decisions.count,
            intentionalRate: intentionalRate,
            delayAdherenceRate: adherenceRate,
            reflectionRate: reflectionRate,
            impulseSpendAvoided: impulseSpendAvoided,
            averageRegretDelta: averageRegretDelta,
            latestDecisionDate: latestDecisionDate,
            earliestDecisionDate: earliestDecisionDate
        )
    }

    func categoryBreakdown(from decisions: [CompletionHistory]) -> [HistoryCategoryStat] {
        guard !decisions.isEmpty else { return [] }

        let totalCount = Double(decisions.count)
        let grouped = Dictionary(grouping: decisions, by: \.category)

        return grouped
            .map { category, entries in
                let intentional = entries.filter { $0.outcome.isIntentional }.count
                return HistoryCategoryStat(
                    category: category,
                    count: entries.count,
                    share: Double(entries.count) / totalCount,
                    intentionalShare: entries.isEmpty ? 0 : Double(intentional) / Double(entries.count)
                )
            }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.category.displayName < rhs.category.displayName
                }
                return lhs.count > rhs.count
            }
    }

    func monthlyRhythm(
        from decisions: [CompletionHistory],
        months: Int = 6,
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> [HistoryMonthStat] {
        guard months > 0 else { return [] }

        let currentMonth = monthStart(for: referenceDate, calendar: calendar)
        let monthStarts = (0..<months)
            .reversed()
            .compactMap { offset in
                calendar.date(byAdding: .month, value: -offset, to: currentMonth)
            }

        let groupedByMonth = Dictionary(grouping: decisions) { decision in
            monthStart(for: decision.completedAt, calendar: calendar)
        }

        let maxCount = monthStarts.map { groupedByMonth[$0]?.count ?? 0 }.max() ?? 0

        return monthStarts.map { month in
            let monthEntries = groupedByMonth[month] ?? []
            let count = monthEntries.count
            let resolved = monthEntries.filter { $0.outcome != .postponed && $0.outcome != .canceled }
            let intentionalRate = resolved.isEmpty
                ? 0
                : Double(resolved.filter { $0.outcome.isIntentional }.count) / Double(resolved.count)

            let relativeIntensity = maxCount == 0 ? 0 : Double(count) / Double(maxCount)

            return HistoryMonthStat(
                monthStart: month,
                count: count,
                intentionalRate: intentionalRate,
                relativeIntensity: relativeIntensity
            )
        }
    }

    func filteredDecisions(
        from decisions: [CompletionHistory],
        category: DeferCategory?
    ) -> [CompletionHistory] {
        guard let category else { return decisions }
        return decisions.filter { $0.category == category }
    }

    func timelineGroups(
        from decisions: [CompletionHistory],
        calendar: Calendar = .current
    ) -> [HistoryTimelineGroup] {
        let grouped = Dictionary(grouping: decisions) { decision in
            monthStart(for: decision.completedAt, calendar: calendar)
        }

        return grouped
            .keys
            .sorted(by: >)
            .map { monthStart in
                let monthDecisions = (grouped[monthStart] ?? [])
                    .sorted { $0.completedAt > $1.completedAt }

                return HistoryTimelineGroup(
                    monthStart: monthStart,
                    decisions: monthDecisions
                )
            }
    }

    func historySubtitle(for summary: HistorySummaryMetrics) -> String {
        guard summary.decisionCount > 0,
              let earliestDate = summary.earliestDecisionDate,
              let latestDate = summary.latestDecisionDate else {
            return "No decisions logged yet"
        }

        if Calendar.current.isDate(earliestDate, equalTo: latestDate, toGranularity: .month) {
            return "All outcomes from \(Self.monthYearFormatter.string(from: latestDate))"
        }

        let startText = Self.monthFormatter.string(from: earliestDate)
        let endText = Self.monthYearFormatter.string(from: latestDate)
        return "\(summary.decisionCount) outcomes from \(startText) to \(endText)"
    }

    private func monthStart(for date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}
