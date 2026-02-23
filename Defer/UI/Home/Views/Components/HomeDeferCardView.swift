import SwiftUI

struct HomeDeferCardView: View {
    let item: DeferItem
    let showWhyReminder: Bool
    let onLogUrge: () -> Void
    let onUseFallback: () -> Void
    let onDecideNow: () -> Void
    let onPostpone: () -> Void
    let onMarkGaveIn: () -> Void
    let onCardTap: () -> Void

    @AppStorage(AppCurrencySettingsStore.Keys.currencyCode)
    private var currencyCode = AppCurrencySettingsStore.defaultCurrencyCode

    private var progress: Double { item.progressPercent() }
    private var statusColor: Color { DeferTheme.statusColor(for: item.status.normalizedLifecycle) }
    private var isResolved: Bool { item.status.normalizedLifecycle.isTerminal }
    private var homeStatusLabel: String {
        switch item.status.normalizedLifecycle {
        case .activeWait:
            return "Active"
        default:
            return item.status.normalizedLifecycle.displayName
        }
    }

    private var urgencyLabel: String {
        if item.isCheckpointDue(referenceDate: .now) {
            return "Decision due now"
        }

        let hours = item.hoursRemaining(from: .now)
        if hours < 24 {
            return "\(hours)h to checkpoint"
        }

        let days = max(1, item.daysRemaining())
        return "\(days)d to checkpoint"
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

                Text(homeStatusLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(statusColor.opacity(0.9)))
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: item.isCheckpointDue(referenceDate: .now) ? "exclamationmark.triangle.fill" : "clock.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.isCheckpointDue(referenceDate: .now) ? DeferTheme.warning : DeferTheme.success)

                Text(urgencyLabel)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer(minLength: 0)

                if let estimatedCost = item.estimatedCost {
                    Text(CurrencyAmountFormatter.wholeAmount(estimatedCost, currencyCode: currencyCode))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                }
            }

            if showWhyReminder {
                whyReminderView
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(item.delayProtocolType.displayName, systemImage: "hourglass")
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
            if item.isCheckpointDue(referenceDate: .now) {
                quickButton(
                    title: "Decide Now",
                    icon: "checkmark.circle",
                    color: DeferTheme.warning,
                    isDisabled: isResolved,
                    action: onDecideNow
                )
            } else {
                quickButton(
                    title: "Log Urge",
                    icon: "waveform.path.ecg",
                    color: DeferTheme.success,
                    isDisabled: isResolved,
                    action: onLogUrge
                )
            }

            if let fallback = item.fallbackAction,
               !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                quickButton(
                    title: "Use Fallback",
                    icon: "shield.checkered",
                    color: DeferTheme.accent,
                    isDisabled: isResolved,
                    action: onUseFallback
                )
            }

            Spacer(minLength: 0)

            Menu {
                Button(action: onLogUrge) {
                    Label("Log urge", systemImage: "waveform.path.ecg")
                }
                .disabled(isResolved)

                Button(action: onUseFallback) {
                    Label("Use fallback", systemImage: "shield.checkered")
                }
                .disabled(isResolved)

                Button(action: onDecideNow) {
                    Label("Decide now", systemImage: "checkmark.circle")
                }
                .disabled(isResolved)

                Button(action: onPostpone) {
                    Label("Postpone", systemImage: "calendar.badge.clock")
                }
                .disabled(isResolved)

                Button(role: .destructive, action: onMarkGaveIn) {
                    Label("Record gave in", systemImage: "xmark.circle")
                }
                .disabled(isResolved)
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

    private var whyReminderView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "quote.bubble.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DeferTheme.warning)
                Text("Why this matters")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.86))
            }

            if let reason = item.whyItMatters,
               !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textPrimary.opacity(0.92))
                    .lineLimit(3)
            } else {
                Text("Add a reason in Edit to strengthen this checkpoint.")
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.76))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
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
        title: "Buy new headphones",
        details: "Wait and compare against what I already own.",
        category: .spending,
        status: .activeWait,
        strictMode: false,
        streakCount: 0,
        startDate: Calendar.current.date(byAdding: .hour, value: -12, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .hour, value: 12, to: .now) ?? .now
    )
    item.whyItMatters = "I want to avoid spending from impulse."
    item.fallbackAction = "Add to wishlist and revisit tomorrow."

    return ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeDeferCardView(
            item: item,
            showWhyReminder: true,
            onLogUrge: {},
            onUseFallback: {},
            onDecideNow: {},
            onPostpone: {},
            onMarkGaveIn: {},
            onCardTap: {}
        )
        .padding()
    }
}
