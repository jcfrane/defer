import SwiftUI

struct HomeFocusCardView: View {
    let stats: HomeStats
    let liveCount: Int

    private var title: String {
        if stats.active == 0 {
            return "Fresh slate, ready to begin"
        }

        if stats.dueSoon > 0 {
            return "Keep pressure low, momentum high"
        }

        return "Strong rhythm this week"
    }

    private var subtitle: String {
        if stats.active == 0 {
            return "Create a new defer and start your next intentional streak."
        }

        if stats.dueSoon > 0 {
            return "A few goals are nearing target dates. Stay locked in."
        }

        return "Your active goals are paced well. Keep your streaks protected."
    }

    var body: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Focus Pulse")
                    .font(.caption.weight(.semibold))
                    .tracking(0.7)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.72))

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    .lineLimit(2)

                HStack(spacing: DeferTheme.spacing(0.75)) {
                    HomeInfoChip(icon: "target", text: "\(stats.active) active", color: DeferTheme.success)
                    HomeInfoChip(icon: "clock.fill", text: "\(stats.dueSoon) due soon", color: DeferTheme.warning)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DeferTheme.success.opacity(0.95),
                                DeferTheme.moss.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: DeferTheme.success.opacity(0.34), radius: 14, y: 6)

                VStack(spacing: 2) {
                    Text("\(liveCount)")
                        .font(.title3.weight(.bold))
                    Text("live")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.7)
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

private struct HomeInfoChip: View {
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
        .foregroundStyle(DeferTheme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeFocusCardView(
            stats: HomeStats(active: 3, longestStreak: 12, dueSoon: 1),
            liveCount: 2
        )
        .padding()
    }
}
