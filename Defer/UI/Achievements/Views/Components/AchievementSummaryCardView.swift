import SwiftUI

struct AchievementSummaryCardView: View {
    let unlockedCount: Int
    let totalCount: Int
    let completionRatio: Double
    let summaryTitle: String
    let summarySubtitle: String

    var body: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Badge Vault")
                    .font(.caption.weight(.semibold))
                    .tracking(0.7)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.72))

                Text(summaryTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(summarySubtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))

                HStack(spacing: DeferTheme.spacing(0.75)) {
                    AchievementStatChip(icon: "rosette", text: "\(unlockedCount) unlocked", color: DeferTheme.success)
                    AchievementStatChip(icon: "flag.checkered", text: "\(totalCount) total", color: DeferTheme.warning)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DeferTheme.primary.opacity(0.9),
                                DeferTheme.warning.opacity(0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.12),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: DeferTheme.primary.opacity(0.45), radius: 14, y: 6)

                VStack(spacing: 2) {
                    Text("\(Int((completionRatio * 100).rounded()))%")
                        .font(.title3.weight(.bold))
                    Text("complete")
                        .font(.system(size: 9, weight: .regular))
                        .textCase(.uppercase)
                        .tracking(0.4)
                        .foregroundStyle(DeferTheme.textPrimary.opacity(0.86))
                }
                .foregroundStyle(DeferTheme.textPrimary)
            }
        }
        .padding(DeferTheme.spacing(2))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.13),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 18, y: 10)
    }
}

private struct AchievementStatChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.17))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.24), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        AchievementSummaryCardView(
            unlockedCount: 3,
            totalCount: AchievementCatalog.all.count,
            completionRatio: 0.38,
            summaryTitle: "Collection is growing steadily",
            summarySubtitle: "5 completions and a best streak of 12 days."
        )
        .padding()
    }
}
