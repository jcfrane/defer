import SwiftUI

struct HomeDeferCardView: View {
    let item: DeferItem
    let onCheckIn: () -> Void
    let onMarkFailed: () -> Void
    let onTogglePause: () -> Void
    let onCardTap: () -> Void

    private var daysRemaining: Int { item.daysRemaining() }
    private var progress: Double { item.progressPercent() }
    private var checkInDisabled: Bool { item.hasCheckedIn() || item.status != .active }
    private var pauseDisabled: Bool { item.status == .failed || item.status == .completed }
    private var shouldShowPauseAction: Bool { item.strictMode || item.status == .paused }
    private var failDisabled: Bool { item.status.isTerminal }
    private var shouldFeatureCheckIn: Bool {
        item.strictMode && item.status == .active && !item.hasCheckedIn()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(2)) {
            HStack(spacing: DeferTheme.spacing(1.25)) {
                Image(systemName: DeferTheme.categoryIcon(for: item.category))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(DeferTheme.surface.opacity(0.82)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text(item.category.displayName)
                        .font(.caption2)
                        .foregroundStyle(DeferTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DeferTheme.surface.opacity(0.68))
                                .overlay(
                                    Capsule()
                                        .stroke(DeferTheme.cardStroke, lineWidth: 1)
                                )
                        )
                }

                Spacer()

                Text(item.status.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(DeferTheme.statusColor(for: item.status).opacity(0.9)))
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(daysRemaining)")
                    .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(daysRemaining == 1 ? "day left" : "days left")
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Streak \(item.streakCount)", systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted)
                }

                ProgressView(value: progress)
                    .tint(DeferTheme.accent)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }

            actionRow
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap()
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            if shouldFeatureCheckIn {
                quickButton(
                    title: "Check In",
                    icon: "checkmark.circle",
                    color: DeferTheme.success,
                    isDisabled: checkInDisabled,
                    action: onCheckIn
                )
            } else if item.hasCheckedIn() {
                Label("Checked today", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                    .padding(.leading, 2)
            }

            Spacer(minLength: 0)

            Menu {
                if !shouldFeatureCheckIn {
                    Button(action: onCheckIn) {
                        Label(
                            item.hasCheckedIn() ? "Checked Today" : "Check In",
                            systemImage: item.hasCheckedIn() ? "checkmark.circle.fill" : "checkmark.circle"
                        )
                    }
                    .disabled(checkInDisabled)
                }

                if shouldShowPauseAction {
                    Button(action: onTogglePause) {
                        Label(item.status == .paused ? "Resume" : "Pause", systemImage: item.status == .paused ? "play.fill" : "pause.fill")
                    }
                    .disabled(pauseDisabled)
                }

                Button(role: .destructive, action: onMarkFailed) {
                    Label("Mark Failed", systemImage: "xmark.circle")
                }
                .disabled(failDisabled)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 34, height: 34)
                    .foregroundStyle(DeferTheme.textPrimary.opacity(0.82))
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
            }
            .accessibilityLabel("More actions")
            .buttonStyle(.plain)
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
        .foregroundStyle(DeferTheme.textPrimary)
        .background(Capsule().fill(color.opacity(isDisabled ? 0.35 : 0.95)))
        .disabled(isDisabled)
    }
}

#Preview {
    let item = PreviewFixtures.sampleDefer(
        title: "No Sugar Weekdays",
        details: "Avoid sugar Monday through Friday.",
        category: .nutrition,
        status: .active,
        strictMode: true,
        streakCount: 6,
        startDate: Calendar.current.date(byAdding: .day, value: -8, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .day, value: 18, to: .now) ?? .now
    )
    item.lastCheckInDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)

    return ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeDeferCardView(
            item: item,
            onCheckIn: {},
            onMarkFailed: {},
            onTogglePause: {},
            onCardTap: {}
        )
        .padding()
    }
}
