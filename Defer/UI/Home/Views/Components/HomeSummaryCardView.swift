import SwiftUI

struct HomeSummaryCardView: View {
    let stats: HomeStats
    @State private var showsMetricTooltip = false

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            HStack(spacing: DeferTheme.spacing(0.75)) {
                Text("Decision Quality")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer(minLength: 0)

                Label(
                    showsMetricTooltip ? "Hide help" : "How this works",
                    systemImage: showsMetricTooltip ? "info.circle.fill" : "info.circle"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.92))
                .labelStyle(.iconOnly)
            }

            if showsMetricTooltip {
                HomeSummaryMetricTooltipView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: DeferTheme.spacing(1.5)) {
                HomeStatTileView(
                    title: "Intentional",
                    value: percent(stats.intentionalRate),
                    icon: "checkmark.seal.fill"
                )
                HomeStatTileView(
                    title: "Defer Honored",
                    value: percent(stats.delayAdherenceRate),
                    icon: "clock.badge.checkmark"
                )
                HomeStatTileView(
                    title: "Reflection",
                    value: percent(stats.reflectionRate),
                    icon: "text.book.closed.fill"
                )
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
        .contentShape(RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous))
        .onTapGesture {
            AppHaptics.selection()
            withAnimation(.easeInOut(duration: 0.18)) {
                showsMetricTooltip.toggle()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Decision Quality summary")
        .accessibilityHint(
            showsMetricTooltip
            ? "Hides metric definitions."
            : "Shows what Intentional, Defer Honored, and Reflection mean."
        )
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private struct HomeSummaryMetricTooltipView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.9)) {
            Text("How these percentages work")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.textPrimary)

            Text("All three use completed decisions as the base. Postponed and canceled entries are excluded.")
                .font(.caption2)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            HomeSummaryMetricTooltipRow(
                icon: "checkmark.seal.fill",
                title: "Intentional",
                detail: "Share of completed decisions marked Resisted or Intentional Yes. This reflects deliberate choice quality."
            )
            HomeSummaryMetricTooltipRow(
                icon: "clock.badge.checkmark",
                title: "Defer Honored",
                detail: "Share of completed decisions made at or after the checkpoint time. This reflects how well you followed your Defer plan."
            )
            HomeSummaryMetricTooltipRow(
                icon: "text.book.closed.fill",
                title: "Reflection",
                detail: "Share of completed decisions with a saved reflection note. This reflects learning and review consistency."
            )

            Text("Tap this card again to hide.")
                .font(.caption2.weight(.medium))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
        }
        .padding(.horizontal, DeferTheme.spacing(1.25))
        .padding(.vertical, DeferTheme.spacing(1))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeferTheme.surface.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

private struct HomeSummaryMetricTooltipRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: DeferTheme.spacing(0.75)) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.9))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HomeStatTileView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(DeferTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(1.5))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DeferTheme.surface.opacity(0.68))
        )
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeSummaryCardView(
            stats: HomeStats(
                activeWait: 4,
                checkpointDue: 1,
                recentUrges: 6,
                intentionalRate: 0.66,
                delayAdherenceRate: 0.72,
                reflectionRate: 0.41
            )
        )
        .padding()
    }
}
