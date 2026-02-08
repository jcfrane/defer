import SwiftUI

struct HomeSummaryCardView: View {
    let stats: HomeStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Growth Through Restraint")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                HomeStatTileView(title: "Active", value: "\(stats.active)", icon: "target")
                HomeStatTileView(title: "Best Streak", value: "\(stats.longestStreak)", icon: "flame.fill")
                HomeStatTileView(title: "Due Soon", value: "\(stats.dueSoon)", icon: "clock.fill")
            }
        }
        .padding(18)
        .glassCard()
    }
}

private struct HomeStatTileView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(DeferTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.14))
        )
    }
}
