import SwiftUI

struct HistoryTimelineSectionView: View {
    let timelineGroups: [HistoryTimelineGroup]
    let selectedCategory: DeferCategory?
    let onClearFilter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Timeline")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(overviewLabel)
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                }

                Spacer()

                if selectedCategory != nil {
                    Button("Clear filter", action: onClearFilter)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
            }

            if timelineGroups.isEmpty {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                    Text("No completions in this filter")
                        .font(.headline)
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text("Try another category or view all completions.")
                        .font(.subheadline)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                }
                .padding(DeferTheme.spacing(1.5))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
            } else {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
                    ForEach(timelineGroups) { group in
                        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                            Text(Self.monthFormatter.string(from: group.monthStart).uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.84))
                                .padding(.horizontal, 4)

                            VStack(spacing: DeferTheme.spacing(1)) {
                                ForEach(Array(group.completions.enumerated()), id: \.element.id) { index, completion in
                                    HistoryTimelineItemRowView(
                                        completion: completion,
                                        showConnector: index != group.completions.count - 1
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private var totalCount: Int {
        timelineGroups.reduce(0) { $0 + $1.completions.count }
    }

    private var overviewLabel: String {
        if let selectedCategory {
            return "\(totalCount) in \(selectedCategory.displayName)"
        }

        return totalCount == 1 ? "1 completion" : "\(totalCount) completions"
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

private struct HistoryTimelineItemRowView: View {
    let completion: CompletionHistory
    let showConnector: Bool

    var body: some View {
        HStack(alignment: .top, spacing: DeferTheme.spacing(1)) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(DeferTheme.success.opacity(0.28))
                        .frame(width: 24, height: 24)

                    Image(systemName: DeferTheme.categoryIcon(for: completion.category))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)
                }

                if showConnector {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.26), Color.white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 72)
                }
            }
            .frame(width: 26)

            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.9)) {
                HStack(alignment: .top, spacing: 8) {
                    Text(completion.deferTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Text(completion.completedAt, format: .dateTime.month(.wide).day().year())
                        .font(.caption.weight(.medium))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.76))
                        .multilineTextAlignment(.trailing)
                }

                HStack(spacing: 6) {
                    timelineTag(
                        title: completion.category.displayName,
                        icon: DeferTheme.categoryIcon(for: completion.category),
                        tint: DeferTheme.success
                    )

                    timelineTag(
                        title: "\(completion.durationDays)d",
                        icon: "timer",
                        tint: DeferTheme.warning
                    )
                }

                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.86))
                    .lineLimit(3)
            }
            .padding(.horizontal, DeferTheme.spacing(1.3))
            .padding(.vertical, DeferTheme.spacing(1.2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
            )
        }
    }

    private var summaryText: String {
        guard let summary = completion.summary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty else {
            return "Completed in \(completion.durationDays) days."
        }

        return summary
    }

    private func timelineTag(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))

            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(DeferTheme.textPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(tint.opacity(0.32))
        )
    }
}

#Preview {
    let first = PreviewFixtures.sampleDefer(
        title: "No Social Media After 9PM",
        details: "Phone off by 9 PM daily.",
        category: .habit,
        status: .completed,
        strictMode: false,
        streakCount: 21,
        startDate: Calendar.current.date(byAdding: .day, value: -24, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now
    )

    let second = PreviewFixtures.sampleDefer(
        title: "No Late-Night Snacking",
        details: "Cut snacks after 9 PM.",
        category: .nutrition,
        status: .completed,
        strictMode: true,
        streakCount: 32,
        startDate: Calendar.current.date(byAdding: .day, value: -35, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now
    )

    let completionOne = PreviewFixtures.sampleCompletion(
        item: first,
        completedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    )

    let completionTwo = PreviewFixtures.sampleCompletion(
        item: second,
        completedAt: Calendar.current.date(byAdding: .day, value: -12, to: .now) ?? .now
    )

    let groupOne = HistoryTimelineGroup(
        monthStart: Calendar.current.date(byAdding: .month, value: 0, to: .now) ?? .now,
        completions: [completionOne]
    )

    let groupTwo = HistoryTimelineGroup(
        monthStart: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now,
        completions: [completionTwo]
    )

    return ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()

        HistoryTimelineSectionView(
            timelineGroups: [groupOne, groupTwo],
            selectedCategory: nil,
            onClearFilter: {}
        )
        .padding()
    }
}
