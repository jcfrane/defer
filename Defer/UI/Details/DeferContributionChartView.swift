import SwiftUI

private let contributionFailRed = Color(red: 0.86, green: 0.28, blue: 0.24)

private enum DeferContributionState: Equatable {
    case success
    case paused
    case failed
    case neutral
    case upcoming
    case outOfRange

    var fillColor: Color {
        switch self {
        case .success:
            return DeferTheme.success
        case .paused:
            return DeferTheme.warning
        case .failed:
            return contributionFailRed
        case .neutral:
            return Color.white.opacity(0.24)
        case .upcoming:
            return Color.clear
        case .outOfRange:
            return Color.white.opacity(0.05)
        }
    }

    var borderColor: Color {
        switch self {
        case .success:
            return DeferTheme.success.opacity(0.95)
        case .paused:
            return DeferTheme.warning.opacity(0.95)
        case .failed:
            return contributionFailRed.opacity(0.95)
        case .neutral:
            return Color.white.opacity(0.3)
        case .upcoming:
            return Color.white.opacity(0.22)
        case .outOfRange:
            return Color.white.opacity(0.08)
        }
    }

    var label: String {
        switch self {
        case .success:
            return "Checked in"
        case .paused:
            return "Paused"
        case .failed:
            return "Failed"
        case .neutral:
            return "No event"
        case .upcoming:
            return "Upcoming"
        case .outOfRange:
            return "Outside window"
        }
    }
}

private struct DeferContributionDay: Identifiable {
    let date: Date
    let state: DeferContributionState
    let isInRange: Bool

    var id: Date { date }
}

private struct DeferContributionWeek: Identifiable {
    let id: Int
    let days: [DeferContributionDay]
}

private struct DeferContributionSnapshot {
    let weeks: [DeferContributionWeek]
    let trackedDays: Int
    let upcomingDays: Int
}

private struct DeferMonthSegment: Identifiable {
    let id: String
    let label: String
    let weekCount: Int
}

struct DeferContributionChartView: View {
    let item: DeferItem

    @State private var selectedDate: Date?
    @State private var revealGrid = false

    private let calendar = Calendar.current
    private let cellSize: CGFloat = 17
    private let cellSpacing: CGFloat = 5

    private static let infoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    private var snapshot: DeferContributionSnapshot {
        makeSnapshot()
    }

    private var selectedDay: DeferContributionDay? {
        guard let selectedDate else { return nil }
        return snapshot.weeks
            .flatMap(\.days)
            .first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var todayWeekID: Int? {
        snapshot.weeks.first {
            $0.days.contains { calendar.isDate($0.date, inSameDayAs: .now) }
        }?.id
    }

    private var monthSegments: [DeferMonthSegment] {
        var segments: [DeferMonthSegment] = []
        guard !snapshot.weeks.isEmpty else { return segments }

        var currentKey: String?
        var currentLabel = ""
        var currentCount = 0
        var segmentIndex = 0

        for week in snapshot.weeks {
            let date = referenceDate(for: week)
            let key = monthKey(for: date)
            let label = Self.monthFormatter.string(from: date)

            if key == currentKey {
                currentCount += 1
            } else {
                if let currentKey {
                    segments.append(
                        DeferMonthSegment(
                            id: "\(currentKey)-\(segmentIndex)",
                            label: currentLabel,
                            weekCount: currentCount
                        )
                    )
                    segmentIndex += 1
                }

                currentKey = key
                currentLabel = label
                currentCount = 1
            }
        }

        if let currentKey {
            segments.append(
                DeferMonthSegment(
                    id: "\(currentKey)-\(segmentIndex)",
                    label: currentLabel,
                    weekCount: currentCount
                )
            )
        }

        return segments
    }

    private var weeklyInsightText: String {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now) else {
            return "No weekly insight yet."
        }

        let start = calendar.startOfDay(for: weekInterval.start)
        let end = weekInterval.end
        let records = latestRecordByDay().values.filter {
            $0.date >= start && $0.date < end
        }

        let checkIns = records.filter { $0.status == .success }.count
        let pauses = records.filter { $0.status == .skipped }.count
        let fails = records.filter { $0.status == .failed }.count

        return "\(checkIns) check-in\(checkIns == 1 ? "" : "s") this week • \(pauses) paused • \(fails) failed"
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let firstIndex = max(0, min(calendar.firstWeekday - 1, symbols.count - 1))
        var ordered: [String] = []
        ordered.reserveCapacity(symbols.count)

        for offset in 0..<symbols.count {
            let index = (firstIndex + offset) % symbols.count
            ordered.append(symbols[index])
        }

        return ordered
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            HStack(spacing: 8) {
                legendChip("Check-in", color: DeferTheme.success)
                legendChip("Pause", color: DeferTheme.warning)
                legendChip("Fail", color: contributionFailRed)
            }

            VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                            monthMarkerRow

                            HStack(alignment: .top, spacing: DeferTheme.spacing(0.9)) {
                                weekdayGuide

                                HStack(alignment: .top, spacing: cellSpacing) {
                                    ForEach(Array(snapshot.weeks.enumerated()), id: \.element.id) { index, week in
                                        VStack(spacing: cellSpacing) {
                                            ForEach(week.days) { day in
                                                daySquare(day)
                                            }
                                        }
                                        .id(week.id)
                                        .opacity(revealGrid ? 1 : 0)
                                        .offset(y: revealGrid ? 0 : 6)
                                        .animation(
                                            .spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.015),
                                            value: revealGrid
                                        )
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.bottom, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear {
                        guard let todayWeekID else { return }
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                proxy.scrollTo(todayWeekID, anchor: .center)
                            }
                        }
                    }
                }

                selectionSummary

                Text(weeklyInsightText)
                    .font(.caption2)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            }
            .padding(.horizontal, DeferTheme.spacing(1))
            .padding(.vertical, DeferTheme.spacing(1))
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )

        }
        .onAppear {
            if selectedDate == nil {
                selectedDate = calendar.startOfDay(for: .now)
            }

            guard !revealGrid else { return }
            revealGrid = true
        }
    }

    private var weekdayGuide: some View {
        VStack(spacing: cellSpacing) {
            ForEach(Array(orderedWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(String(symbol.prefix(3)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                    .frame(width: 32, height: cellSize, alignment: .leading)
            }
        }
    }

    private var monthMarkerRow: some View {
        HStack(alignment: .center, spacing: DeferTheme.spacing(0.9)) {
            Color.clear
                .frame(width: 32, height: 10)

            HStack(spacing: cellSpacing) {
                ForEach(monthSegments) { segment in
                    Text(segment.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.72))
                        .frame(
                            width: widthForMonthSegment(weeks: segment.weekCount),
                            alignment: .leading
                        )
                }
            }
        }
    }

    private var selectionSummary: some View {
        Group {
            if let selectedDay {
                HStack(spacing: 8) {
                    Circle()
                        .fill(selectedDay.state.fillColor)
                        .frame(width: 8, height: 8)

                    Text(
                        "\(Self.infoDateFormatter.string(from: selectedDay.date)) • \(selectedDay.state.label)"
                    )
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.86))
                    .lineLimit(1)

                    Spacer()

                    Text("\(snapshot.trackedDays)d tracked • \(snapshot.upcomingDays)d upcoming")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.76))
                }
            } else {
                Text("Tap a square to inspect that day.")
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.84))
            }
        }
        .padding(.top, 2)
    }

    private func legendChip(_ title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(title)
                .font(.caption2)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.84))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func daySquare(_ day: DeferContributionDay) -> some View {
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day.date) } ?? false

        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(day.state.fillColor)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.95) : day.state.borderColor,
                        lineWidth: isSelected ? 1.4 : 0.8
                    )
            )
            .opacity(day.isInRange ? 1 : 0.22)
            .contentShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .onTapGesture {
                guard day.isInRange else { return }
                AppHaptics.selection()
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDate = day.date
                }
            }
            .accessibilityLabel(
                "\(Self.infoDateFormatter.string(from: day.date)), \(day.state.label)"
            )
    }

    private func widthForMonthSegment(weeks: Int) -> CGFloat {
        guard weeks > 0 else { return 0 }
        return (CGFloat(weeks) * cellSize) + (CGFloat(max(0, weeks - 1)) * cellSpacing)
    }

    private func referenceDate(for week: DeferContributionWeek) -> Date {
        week.days.first(where: \.isInRange)?.date ?? week.days.first?.date ?? .now
    }

    private func monthKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }

    private func makeSnapshot() -> DeferContributionSnapshot {
        let today = calendar.startOfDay(for: .now)
        let itemStart = calendar.startOfDay(for: item.startDate)
        let recentPastCap = calendar.date(byAdding: .day, value: -(26 * 7 - 1), to: today) ?? itemStart

        let unclampedStart = itemStart > recentPastCap ? itemStart : recentPastCap
        let visibleStart = unclampedStart <= today ? unclampedStart : today
        let rawFutureEnd = max(today, calendar.startOfDay(for: item.targetDate))
        let futureCapEnd = calendar.date(byAdding: .day, value: 52 * 7 - 1, to: visibleStart) ?? rawFutureEnd
        let visibleEnd = min(rawFutureEnd, futureCapEnd)

        let firstGridDay = startOfWeek(containing: visibleStart)
        let lastGridDay = endOfWeek(containing: visibleEnd)

        let recordByDay = latestRecordByDay()
        let failureFallbackDay = calendar.startOfDay(for: item.updatedAt)

        var weeks: [DeferContributionWeek] = []
        weeks.reserveCapacity(32)

        var weekCursor = firstGridDay
        var weekIndex = 0

        while weekCursor <= lastGridDay {
            var days: [DeferContributionDay] = []
            days.reserveCapacity(7)

            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekCursor) else {
                    continue
                }

                let day = calendar.startOfDay(for: date)
                let isInRange = day >= visibleStart && day <= visibleEnd
                let isFuture = day > today

                let state: DeferContributionState
                if !isInRange {
                    state = .outOfRange
                } else if let record = recordByDay[day] {
                    state = contributionState(for: record.status)
                } else if isFuture {
                    state = .upcoming
                } else if item.status == .paused && calendar.isDate(day, inSameDayAs: today) {
                    state = .paused
                } else if item.status == .failed && calendar.isDate(day, inSameDayAs: failureFallbackDay) {
                    state = .failed
                } else {
                    state = .neutral
                }

                days.append(
                    DeferContributionDay(
                        date: day,
                        state: state,
                        isInRange: isInRange
                    )
                )
            }

            weeks.append(DeferContributionWeek(id: weekIndex, days: days))
            weekIndex += 1

            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: weekCursor) else {
                break
            }
            weekCursor = nextWeek
        }

        let trackedDays = weeks.flatMap(\.days).filter(\.isInRange)
        let trackedPastDays = trackedDays.filter { $0.date <= today }.count
        let futureDays = trackedDays.filter { $0.date > today }.count
        return DeferContributionSnapshot(
            weeks: weeks,
            trackedDays: trackedPastDays,
            upcomingDays: futureDays
        )
    }

    private func latestRecordByDay() -> [Date: StreakRecord] {
        var records: [Date: StreakRecord] = [:]

        for record in item.streakRecords {
            let day = calendar.startOfDay(for: record.date)

            guard let existing = records[day] else {
                records[day] = record
                continue
            }

            if record.createdAt > existing.createdAt {
                records[day] = record
            }
        }

        return records
    }

    private func contributionState(for streakStatus: StreakEntryStatus) -> DeferContributionState {
        switch streakStatus {
        case .success:
            return .success
        case .failed:
            return .failed
        case .skipped:
            return .paused
        }
    }

    private func startOfWeek(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private func endOfWeek(containing date: Date) -> Date {
        guard
            let interval = calendar.dateInterval(of: .weekOfYear, for: date),
            let dayBeforeEnd = calendar.date(byAdding: .day, value: -1, to: interval.end)
        else {
            return calendar.startOfDay(for: date)
        }

        return calendar.startOfDay(for: dayBeforeEnd)
    }
}
