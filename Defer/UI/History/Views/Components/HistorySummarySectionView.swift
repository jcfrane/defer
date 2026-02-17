import SwiftUI

struct HistorySummarySectionView: View {
    let summary: HistorySummaryMetrics
    let monthlyRhythm: [HistoryMonthStat]

    private var latestCompletionLabel: String {
        guard let latestDate = summary.latestCompletionDate else {
            return "No recent completion"
        }

        let relative = Self.relativeFormatter.localizedString(for: latestDate, relativeTo: .now)
        return "Latest \(relative)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.75)) {
            HStack(alignment: .top, spacing: DeferTheme.spacing(1.5)) {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.5)) {
                    Text("Completion Pulse")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.84))

                    Text("\(summary.completionCount)")
                        .font(.system(size: 52, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(summary.completionCount == 1 ? "win logged" : "wins logged")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                }

                Spacer(minLength: DeferTheme.spacing(1))

                VStack(alignment: .trailing, spacing: DeferTheme.spacing(0.75)) {
                    Text("Avg")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

                    Text("\(summary.averageDuration)d")
                        .font(.title.weight(.heavy).monospacedDigit())
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(latestCompletionLabel)
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, DeferTheme.spacing(0.75))
                .padding(.horizontal, DeferTheme.spacing(1.25))
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DeferTheme.surface.opacity(0.62))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            HStack(spacing: DeferTheme.spacing(1)) {
                historyMetricPill(
                    title: "Longest",
                    value: "\(summary.longestDuration)d",
                    icon: "flame.fill",
                    accent: DeferTheme.warning
                )

                historyMetricPill(
                    title: "Active Days",
                    value: "\(summary.activeDays)",
                    icon: "calendar.badge.checkmark",
                    accent: DeferTheme.success
                )

                historyMetricPill(
                    title: "Average",
                    value: "\(summary.averageDuration)d",
                    icon: "clock.arrow.circlepath",
                    accent: DeferTheme.accent
                )
            }

            if !monthlyRhythm.isEmpty {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                    Text("Last 6 months")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))

                    HistoryMonthlyRhythmView(monthlyRhythm: monthlyRhythm)
                }
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .background(summaryBackground)
    }

    private var summaryBackground: some View {
        RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        DeferTheme.surface.opacity(0.9),
                        DeferTheme.surface.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(DeferTheme.warning.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .offset(x: -30, y: -55)
            }
            .shadow(color: .black.opacity(0.2), radius: 20, y: 12)
    }

    private func historyMetricPill(
        title: String,
        value: String,
        icon: String,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            }

            Text(value)
                .font(.headline.weight(.bold).monospacedDigit())
                .foregroundStyle(DeferTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DeferTheme.spacing(1.1))
        .padding(.vertical, DeferTheme.spacing(1))
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}

private struct HistoryMonthlyRhythmView: View {
    let monthlyRhythm: [HistoryMonthStat]

    var body: some View {
        HStack(alignment: .bottom, spacing: DeferTheme.spacing(0.75)) {
            ForEach(monthlyRhythm) { month in
                VStack(spacing: 4) {
                    Text("\(month.count)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(DeferTheme.textMuted.opacity(month.count == 0 ? 0.45 : 0.86))

                    Capsule()
                        .fill(barGradient(for: month))
                        .frame(width: 16, height: barHeight(for: month))

                    Text(Self.monthFormatter.string(from: month.monthStart))
                        .font(.caption2)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func barHeight(for month: HistoryMonthStat) -> CGFloat {
        let minimum: CGFloat = 10
        let maximum: CGFloat = 52
        return minimum + (maximum - minimum) * month.relativeIntensity
    }

    private func barGradient(for month: HistoryMonthStat) -> LinearGradient {
        let intensity = month.relativeIntensity

        if intensity <= 0 {
            return LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [DeferTheme.warning.opacity(0.55 + (intensity * 0.3)), DeferTheme.success.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()

        HistorySummarySectionView(
            summary: HistorySummaryMetrics(
                completionCount: 12,
                averageDuration: 18,
                longestDuration: 46,
                activeDays: 10,
                latestCompletionDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
                earliestCompletionDate: Calendar.current.date(byAdding: .month, value: -5, to: .now)
            ),
            monthlyRhythm: [
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -5, to: .now) ?? .now, count: 1, relativeIntensity: 0.25),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -4, to: .now) ?? .now, count: 2, relativeIntensity: 0.5),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now, count: 0, relativeIntensity: 0),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now, count: 3, relativeIntensity: 0.75),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now, count: 4, relativeIntensity: 1),
                HistoryMonthStat(monthStart: .now, count: 2, relativeIntensity: 0.5)
            ]
        )
        .padding()
    }
}
