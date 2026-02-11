import SwiftUI

struct DeferDetailView: View {
    let item: DeferItem
    let onCheckIn: () -> Void
    let onTogglePause: () -> Void
    let onMarkFailed: () -> Void
    let onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var progress: Double { item.progressPercent() }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DeferTheme.spacing(2)) {
                        AppPageHeaderView(title: item.title)

                        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
                            Text(item.category.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DeferTheme.textMuted)

                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                Text("\(item.daysRemaining())")
                                    .font(.system(size: 42, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(DeferTheme.textPrimary)
                                Text(item.daysRemaining() == 1 ? "day left" : "days left")
                                    .font(.subheadline)
                                    .foregroundStyle(DeferTheme.textMuted)
                            }

                            ProgressView(value: progress)
                                .tint(DeferTheme.accent)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)

                            HStack {
                                detailTag("Status", item.status.displayName)
                                detailTag("Streak", "\(item.streakCount)")
                            }

                            if let details = item.details, !details.isEmpty {
                                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                                    Text("Why I defer this")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(DeferTheme.textMuted)
                                    Text(details)
                                        .font(.body)
                                        .foregroundStyle(DeferTheme.textPrimary)
                                }
                            }
                        }
                        .padding(DeferTheme.spacing(2.25))
                        .glassCard()

                        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
                            Text("Actions")
                                .font(.headline)
                                .foregroundStyle(DeferTheme.textPrimary)

                            HStack(spacing: DeferTheme.spacing(1)) {
                                actionButton(
                                    title: item.hasCheckedIn() ? "Checked" : "Check In",
                                    icon: item.hasCheckedIn() ? "checkmark.circle.fill" : "checkmark.circle",
                                    color: DeferTheme.success,
                                    disabled: item.hasCheckedIn() || item.status != .active,
                                    action: onCheckIn
                                )

                                actionButton(
                                    title: item.status == .paused ? "Resume" : "Pause",
                                    icon: item.status == .paused ? "play.fill" : "pause.fill",
                                    color: DeferTheme.warning,
                                    disabled: item.status.isTerminal,
                                    action: onTogglePause
                                )

                                actionButton(
                                    title: "Fail",
                                    icon: "xmark.circle",
                                    color: DeferTheme.danger,
                                    disabled: item.status.isTerminal,
                                    action: onMarkFailed
                                )
                            }

                            Button {
                                onEdit()
                            } label: {
                                Label("Edit Defer", systemImage: "square.and.pencil")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DeferTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(DeferTheme.surface.opacity(0.85)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(DeferTheme.spacing(2.25))
                        .glassCard()
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 80)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
            }
        }
    }

    private func detailTag(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(DeferTheme.textMuted)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DeferTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Capsule().fill(DeferTheme.surface.opacity(0.75)))
    }

    private func actionButton(
        title: String,
        icon: String,
        color: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(DeferTheme.textPrimary)
        .background(Capsule().fill(color.opacity(disabled ? 0.35 : 0.95)))
        .disabled(disabled)
    }
}
