import SwiftUI

struct HomeFocusCardView: View {
    let stats: HomeStats
    let liveCount: Int

    private var title: String {
        if stats.checkpointDue > 0 {
            return "Checkpoint due"
        }

        if stats.activeWait == 0 {
            return "No active defer"
        }

        return "Defers active"
    }

    private var subtitle: String {
        if stats.checkpointDue > 0 {
            return "Decide due checkpoints first."
        }

        if stats.activeWait == 0 {
            return "Add an intent to start."
        }

        return "Log urges. Use your fallback."
    }

    private var intentionalPercent: Int {
        Int((stats.intentionalRate * 100).rounded())
    }

    var body: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    .lineLimit(2)

                HStack(spacing: DeferTheme.spacing(0.75)) {
                    HomeInfoChip(icon: "clock.fill", text: "\(stats.activeWait) active", color: DeferTheme.success)
                    HomeInfoChip(icon: "exclamationmark.circle.fill", text: "\(stats.checkpointDue) due", color: DeferTheme.warning)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                HomeGrowthTreeView(intentionalRate: stats.intentionalRate)

                Text("Intent \(intentionalPercent)%")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.7)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.9))
            }
        }
        .padding(DeferTheme.spacing(2))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.13), Color.white.opacity(0.05)],
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
            stats: HomeStats(
                activeWait: 3,
                checkpointDue: 1,
                recentUrges: 5,
                intentionalRate: 0.64,
                delayAdherenceRate: 0.71,
                reflectionRate: 0.42
            ),
            liveCount: 3
        )
        .padding()
    }
}
