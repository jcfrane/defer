import Foundation
import Combine

struct HistorySummaryMetrics {
    let completionCount: Int
    let averageDuration: Int
    let longestDuration: Int
    let activeDays: Int
    let latestCompletionDate: Date?
    let earliestCompletionDate: Date?
}

struct HistoryCategoryStat: Identifiable {
    let category: DeferCategory
    let count: Int
    let share: Double

    var id: DeferCategory { category }
}

struct HistoryMonthStat: Identifiable {
    let monthStart: Date
    let count: Int
    let relativeIntensity: Double

    var id: Date { monthStart }
}

struct HistoryTimelineGroup: Identifiable {
    let monthStart: Date
    let completions: [CompletionHistory]

    var id: Date { monthStart }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    func summaryMetrics(
        from completions: [CompletionHistory],
        calendar: Calendar = .current
    ) -> HistorySummaryMetrics {
        guard !completions.isEmpty else {
            return HistorySummaryMetrics(
                completionCount: 0,
                averageDuration: 0,
                longestDuration: 0,
                activeDays: 0,
                latestCompletionDate: nil,
                earliestCompletionDate: nil
            )
        }

        let totalDuration = completions.reduce(0) { $0 + $1.durationDays }
        let averageDuration = totalDuration / completions.count
        let longestDuration = completions.map(\.durationDays).max() ?? 0
        let latestCompletionDate = completions.map(\.completedAt).max()
        let earliestCompletionDate = completions.map(\.completedAt).min()
        let activeDays = Set(completions.map { calendar.startOfDay(for: $0.completedAt) }).count

        return HistorySummaryMetrics(
            completionCount: completions.count,
            averageDuration: averageDuration,
            longestDuration: longestDuration,
            activeDays: activeDays,
            latestCompletionDate: latestCompletionDate,
            earliestCompletionDate: earliestCompletionDate
        )
    }

    func categoryBreakdown(from completions: [CompletionHistory]) -> [HistoryCategoryStat] {
        guard !completions.isEmpty else { return [] }

        let totalCount = Double(completions.count)
        let grouped = Dictionary(grouping: completions, by: \.category)

        return grouped
            .map { category, entries in
                HistoryCategoryStat(
                    category: category,
                    count: entries.count,
                    share: Double(entries.count) / totalCount
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
        from completions: [CompletionHistory],
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

        let groupedByMonth = Dictionary(grouping: completions) { completion in
            monthStart(for: completion.completedAt, calendar: calendar)
        }
        .mapValues(\.count)

        let maxCount = monthStarts.map { groupedByMonth[$0] ?? 0 }.max() ?? 0

        return monthStarts.map { month in
            let count = groupedByMonth[month] ?? 0
            let relativeIntensity: Double

            if maxCount == 0 {
                relativeIntensity = 0
            } else {
                relativeIntensity = Double(count) / Double(maxCount)
            }

            return HistoryMonthStat(
                monthStart: month,
                count: count,
                relativeIntensity: relativeIntensity
            )
        }
    }

    func filteredCompletions(
        from completions: [CompletionHistory],
        category: DeferCategory?
    ) -> [CompletionHistory] {
        guard let category else { return completions }
        return completions.filter { $0.category == category }
    }

    func timelineGroups(
        from completions: [CompletionHistory],
        calendar: Calendar = .current
    ) -> [HistoryTimelineGroup] {
        let grouped = Dictionary(grouping: completions) { completion in
            monthStart(for: completion.completedAt, calendar: calendar)
        }

        return grouped
            .keys
            .sorted(by: >)
            .map { monthStart in
                let monthCompletions = (grouped[monthStart] ?? [])
                    .sorted { $0.completedAt > $1.completedAt }

                return HistoryTimelineGroup(
                    monthStart: monthStart,
                    completions: monthCompletions
                )
            }
    }

    func historySubtitle(for summary: HistorySummaryMetrics) -> String {
        guard summary.completionCount > 0,
              let earliestDate = summary.earliestCompletionDate,
              let latestDate = summary.latestCompletionDate else {
            return "No completions yet"
        }

        if Calendar.current.isDate(earliestDate, equalTo: latestDate, toGranularity: .month) {
            return "All wins from \(Self.monthYearFormatter.string(from: latestDate))"
        }

        let startText = Self.monthFormatter.string(from: earliestDate)
        let endText = Self.monthYearFormatter.string(from: latestDate)
        return "\(summary.completionCount) completions from \(startText) to \(endText)"
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
