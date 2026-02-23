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

                Button {
                    AppHaptics.selection()
                    showsMetricTooltip = true
                } label: {
                    Label("How this works", systemImage: "info.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.92))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("How Decision Quality is calculated")
                .accessibilityHint("Opens metric definitions and formulas.")
            }

            HStack(spacing: DeferTheme.spacing(1.5)) {
                HomeStatTileView(
                    title: "Intentional",
                    value: percent(stats.intentionalRate),
                    icon: "checkmark.seal.fill",
                    iconTint: DeferTheme.textPrimary
                )
                HomeStatTileView(
                    title: "Defer Honored",
                    value: percent(stats.delayAdherenceRate),
                    icon: "clock.badge.checkmark",
                    iconTint: DeferTheme.warning
                )
                HomeStatTileView(
                    title: "Reflection",
                    value: percent(stats.reflectionRate),
                    icon: "text.book.closed.fill",
                    iconTint: DeferTheme.sand
                )
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
        .sheet(isPresented: $showsMetricTooltip) {
            HomeSummaryMetricTooltipView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Decision Quality summary")
        .accessibilityHint("Shows Intentional, Defer Honored, and Reflection rates.")
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

private struct HomeStatTileView: View {
    let title: String
    let value: String
    let icon: String
    let iconTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(iconTint)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(iconTint.opacity(0.24))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(DeferTheme.textPrimary)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DeferTheme.spacing(1.25))
        .padding(.vertical, DeferTheme.spacing(1.35))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
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
