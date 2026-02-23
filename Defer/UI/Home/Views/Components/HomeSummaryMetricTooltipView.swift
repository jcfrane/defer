import SwiftUI

struct HomeSummaryMetricTooltipView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
                    baseRulesCard

                    HomeSummaryMetricDescriptionCard(
                        icon: "checkmark.seal.fill",
                        iconTint: DeferTheme.textPrimary,
                        title: "Intentional",
                        summary: "How often your final decision was deliberate instead of reactive.",
                        countsAs: "Marked as Resisted or Intentional Yes.",
                        notCounted: "Postponed and Canceled outcomes are not included in this metric's base set.",
                        tip: "Use your pause plan before deciding, then record the outcome that best matches your intent."
                    )

                    HomeSummaryMetricDescriptionCard(
                        icon: "clock.badge.checkmark",
                        iconTint: DeferTheme.warning,
                        title: "Defer Honored",
                        summary: "How consistently you kept your delay commitment until checkpoint time.",
                        countsAs: "Resolved decisions made at or after the checkpoint.",
                        notCounted: "Resolved decisions made before checkpoint lower this metric. Postponed and Canceled are excluded from the base set.",
                        tip: "Set realistic checkpoints and use reminders during high-risk windows so you can reach your target time."
                    )

                    HomeSummaryMetricDescriptionCard(
                        icon: "text.book.closed.fill",
                        iconTint: DeferTheme.sand,
                        title: "Reflection",
                        summary: "How often you leave a usable note after a decision.",
                        countsAs: "A non-empty reflection after trimming spaces and line breaks.",
                        notCounted: "Blank reflections do not count as completed reflection entries.",
                        tip: "Capture one trigger and one lesson right after each decision while context is fresh."
                    )

                    Text("Display rounding: each value is shown as a whole percent using standard rounding.")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DeferTheme.spacing(2))
            }
            .background(
                DeferTheme.homeBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("Decision Quality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
                }
            }
        }
    }

    private var baseRulesCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.9)) {
            Text("Base Rules")
                .font(.headline.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)

            Text("All three percentages are computed from resolved decisions only.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DeferTheme.textPrimary)

            Text("Resolved Decisions = CompletionHistory entries where outcome is not Postponed and not Canceled.")
                .font(.caption)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Text("If there are no resolved decisions, all metrics are 0%.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.85))
        }
        .padding(DeferTheme.spacing(1.3))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DeferTheme.surface.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct HomeSummaryMetricDescriptionCard: View {
    let icon: String
    let iconTint: Color
    let title: String
    let summary: String
    let countsAs: String
    let notCounted: String
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
            HStack(spacing: DeferTheme.spacing(0.75)) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(iconTint)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(iconTint.opacity(0.22))
                    )

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
            }

            Text(summary)
                .font(.caption)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                HomeSummaryMetricDetailRow(
                    title: "Counts as",
                    detail: countsAs
                )
                HomeSummaryMetricDetailRow(
                    title: "Not counted",
                    detail: notCounted
                )
                HomeSummaryMetricDetailRow(
                    title: "How to improve",
                    detail: tip
                )
            }
        }
        .padding(DeferTheme.spacing(1.2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DeferTheme.surface.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }
}

private struct HomeSummaryMetricDetailRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DeferTheme.textPrimary.opacity(0.9))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HomeSummaryMetricTooltipView()
}
