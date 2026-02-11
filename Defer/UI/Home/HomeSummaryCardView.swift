import SwiftUI

struct HomeSummaryCardView: View {
    let stats: HomeStats

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            Text("Growth Through Restraint")
                .font(.title2.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)

            HStack(spacing: DeferTheme.spacing(1.5)) {
                HomeStatTileView(title: "Active", value: "\(stats.active)", icon: "target")
                HomeStatTileView(title: "Best Streak", value: "\(stats.longestStreak)", icon: "flame.fill")
                HomeStatTileView(title: "Due Soon", value: "\(stats.dueSoon)", icon: "clock.fill")
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
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
