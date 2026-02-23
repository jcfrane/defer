import SwiftUI

struct HistorySummarySectionView: View {
    let summary: HistorySummaryMetrics
    let monthlyRhythm: [HistoryMonthStat]

    @AppStorage(AppCurrencySettingsStore.Keys.currencyCode)
    private var currencyCode = AppCurrencySettingsStore.defaultCurrencyCode

    private var latestDecisionLabel: String {
        guard let latestDate = summary.latestDecisionDate else {
            return "No recent decision"
        }

        let relative = Self.relativeFormatter.localizedString(for: latestDate, relativeTo: .now)
        return "Latest \(relative)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.75)) {
            HStack(alignment: .top, spacing: DeferTheme.spacing(1.5)) {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.5)) {
                    Text("Decision Pulse")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.84))

                    Text("\(summary.decisionCount)")
                        .font(.system(size: 52, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(summary.decisionCount == 1 ? "outcome logged" : "outcomes logged")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                }

                Spacer(minLength: DeferTheme.spacing(1))

                VStack(alignment: .trailing, spacing: DeferTheme.spacing(0.75)) {
                    Text("Intentional")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

                    Text(percent(summary.intentionalRate))
                        .font(.title.weight(.heavy).monospacedDigit())
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(latestDecisionLabel)
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
                    title: "Delay Honored",
                    value: percent(summary.delayAdherenceRate),
                    icon: "clock.badge.checkmark",
                    accent: DeferTheme.warning
                )

                historyMetricPill(
                    title: "Reflection",
                    value: percent(summary.reflectionRate),
                    icon: "text.book.closed.fill",
                    accent: DeferTheme.success
                )

                historyMetricPill(
                    title: "Spend Avoided",
                    value: CurrencyAmountFormatter.wholeAmount(
                        summary.impulseSpendAvoided,
                        currencyCode: currencyCode
                    ),
                    icon: "dollarsign.circle.fill",
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

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private var summaryBackground: some View {
        RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [DeferTheme.surface.opacity(0.9), DeferTheme.surface.opacity(0.72)],
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

        let intentOpacity = 0.45 + (month.intentionalRate * 0.45)

        return LinearGradient(
            colors: [
                DeferTheme.warning.opacity(intentOpacity),
                DeferTheme.success.opacity(0.9)
            ],
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
                decisionCount: 12,
                intentionalRate: 0.66,
                delayAdherenceRate: 0.71,
                reflectionRate: 0.42,
                impulseSpendAvoided: 186,
                averageRegretDelta: -1.3,
                latestDecisionDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
                earliestDecisionDate: Calendar.current.date(byAdding: .month, value: -5, to: .now)
            ),
            monthlyRhythm: [
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -5, to: .now) ?? .now, count: 1, intentionalRate: 0.5, relativeIntensity: 0.25),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -4, to: .now) ?? .now, count: 2, intentionalRate: 0.45, relativeIntensity: 0.5),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -3, to: .now) ?? .now, count: 0, intentionalRate: 0.0, relativeIntensity: 0),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now, count: 3, intentionalRate: 0.66, relativeIntensity: 0.75),
                HistoryMonthStat(monthStart: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now, count: 4, intentionalRate: 0.75, relativeIntensity: 1),
                HistoryMonthStat(monthStart: .now, count: 2, intentionalRate: 0.5, relativeIntensity: 0.5)
            ]
        )
        .padding()
    }
}
