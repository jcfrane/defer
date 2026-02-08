import SwiftUI

struct HomeDeferCardView: View {
    let item: DeferItem
    let onCheckIn: () -> Void
    let onMarkFailed: () -> Void
    let onTogglePause: () -> Void
    let onCardTap: () -> Void

    private var daysRemaining: Int { item.daysRemaining() }
    private var progress: Double { item.progressPercent() }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: DeferTheme.categoryIcon(for: item.category))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.18)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(item.category.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.16))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                                )
                        )
                }

                Spacer()

                Text(item.status.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(DeferTheme.statusColor(for: item.status).opacity(0.9)))
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(daysRemaining)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(daysRemaining == 1 ? "day left" : "days left")
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Streak \(item.streakCount)", systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted)
                }

                ProgressView(value: progress)
                    .tint(DeferTheme.accent)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }

            HStack(spacing: 8) {
                quickButton(
                    title: item.hasCheckedIn() ? "Checked" : "Check In",
                    icon: item.hasCheckedIn() ? "checkmark.circle.fill" : "checkmark.circle",
                    color: DeferTheme.success,
                    isDisabled: item.hasCheckedIn() || item.status != .active,
                    action: onCheckIn
                )

                quickButton(
                    title: item.status == .paused ? "Resume" : "Pause",
                    icon: item.status == .paused ? "play.fill" : "pause.fill",
                    color: .orange,
                    isDisabled: item.status == .failed || item.status == .completed,
                    action: onTogglePause
                )

                quickButton(
                    title: "Fail",
                    icon: "xmark.circle",
                    color: DeferTheme.danger,
                    isDisabled: item.status.isTerminal,
                    action: onMarkFailed
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(18)
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap()
        }
    }

    private func quickButton(
        title: String,
        icon: String,
        color: Color,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(Capsule().fill(color.opacity(isDisabled ? 0.35 : 0.95)))
        .disabled(isDisabled)
    }
}
