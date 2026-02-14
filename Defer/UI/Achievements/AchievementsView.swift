import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \Achievement.unlockedAt, order: .reverse)
    private var unlockedAchievements: [Achievement]

    @Query(sort: \CompletionHistory.completedAt)
    private var completions: [CompletionHistory]

    @Query(sort: \DeferItem.updatedAt)
    private var defers: [DeferItem]

    private var unlockedByKey: [String: Achievement] {
        Dictionary(uniqueKeysWithValues: unlockedAchievements.map { ($0.key, $0) })
    }

    private var progress: AchievementProgress {
        AchievementProgress.from(defers: defers, completions: completions)
    }

    private var unlockedDefinitions: [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedByKey[$0.key] != nil }
    }

    private var lockedDefinitions: [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedByKey[$0.key] == nil }
    }

    private var completionRatio: Double {
        guard !AchievementCatalog.all.isEmpty else { return 0 }
        return Double(unlockedAchievements.count) / Double(AchievementCatalog.all.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                achievementsAtmosphere

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeferTheme.spacing(1.75)) {
                        AppPageHeaderView(
                            title: "Achievements",
                            subtitle: {
                                Text("Every streak leaves a visible mark.")
                                    .font(.subheadline)
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                            }
                        )

                        summaryCard

                        if !unlockedDefinitions.isEmpty {
                            sectionHeader(
                                title: "Unlocked",
                                subtitle: "\(unlockedDefinitions.count) collected",
                                icon: "checkmark.seal.fill",
                                iconColor: DeferTheme.success
                            )

                            ForEach(unlockedDefinitions) { definition in
                                AchievementBadgeCard(
                                    definition: definition,
                                    unlocked: unlockedByKey[definition.key],
                                    progress: progress
                                )
                            }
                        }

                        if !lockedDefinitions.isEmpty {
                            sectionHeader(
                                title: "In Progress",
                                subtitle: "\(lockedDefinitions.count) to go",
                                icon: "lock.fill",
                                iconColor: DeferTheme.warning
                            )

                            ForEach(lockedDefinitions) { definition in
                                AchievementBadgeCard(
                                    definition: definition,
                                    unlocked: nil,
                                    progress: progress
                                )
                            }
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 84)
                }
            }
        }
    }

    private var achievementsAtmosphere: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.accent.opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 190
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 170, y: -290)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.success.opacity(0.17),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 170
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -170, y: -140)
                .blur(radius: 7)
        }
        .allowsHitTesting(false)
    }

    private var summaryCard: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Progress Gallery")
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
                    statChip(icon: "rosette", text: "\(unlockedAchievements.count) unlocked", color: DeferTheme.success)
                    statChip(icon: "flag.checkered", text: "\(AchievementCatalog.all.count) total", color: DeferTheme.warning)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DeferTheme.accent.opacity(0.94), DeferTheme.warning.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: DeferTheme.accent.opacity(0.4), radius: 14, y: 6)

                VStack(spacing: 2) {
                    Text("\(Int((completionRatio * 100).rounded()))%")
                        .font(.title3.weight(.bold))
                    Text("complete")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.4)
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

    private var summaryTitle: String {
        if unlockedAchievements.isEmpty {
            return "Your first badge is waiting"
        }
        if unlockedAchievements.count == AchievementCatalog.all.count {
            return "Full collection complete"
        }
        return "Collection is growing steadily"
    }

    private var summarySubtitle: String {
        if unlockedAchievements.isEmpty {
            return "Complete your first defer to unlock your first achievement."
        }
        return "\(progress.completionCount) completions and a best streak of \(progress.maxStreak) days."
    }

    private func sectionHeader(title: String, subtitle: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
            }

            Spacer()
        }
        .padding(.top, DeferTheme.spacing(0.5))
    }

    private func statChip(icon: String, text: String, color: Color) -> some View {
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

private struct AchievementBadgeCard: View {
    let definition: AchievementDefinition
    let unlocked: Achievement?
    let progress: AchievementProgress

    private var isUnlocked: Bool { unlocked != nil }

    private var progressTuple: (current: Int, target: Int) {
        definition.rule.progressValue(using: progress)
    }

    private var progressFraction: Double {
        guard progressTuple.target > 0 else { return 0 }
        return min(Double(progressTuple.current) / Double(progressTuple.target), 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DeferTheme.spacing(1.5)) {
            ZStack {
                Circle()
                    .fill(DeferTheme.badgeGradient(for: definition.tier))
                    .frame(width: 56, height: 56)
                    .opacity(isUnlocked ? 1 : 0.42)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isUnlocked ? 0.26 : 0.14), lineWidth: 1)
                    )

                Image(systemName: definition.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary.opacity(isUnlocked ? 1 : 0.8))
                    .symbolEffect(.bounce, value: isUnlocked)
            }

            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                HStack(alignment: .top, spacing: DeferTheme.spacing(0.75)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(definition.title)
                            .font(.headline)
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text(definition.details)
                            .font(.subheadline)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                    }

                    Spacer(minLength: 0)

                    Text(definition.tier.displayName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DeferTheme.badgeColor(for: definition.tier).opacity(0.9))
                        )
                        .foregroundStyle(DeferTheme.textPrimary)
                }

                if let unlocked {
                    Text("Unlocked \(unlocked.unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(DeferTheme.success)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(definition.rule.progressText(using: progress))
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

                        ProgressView(value: progressFraction)
                            .tint(DeferTheme.accent)
                            .scaleEffect(x: 1, y: 1.25, anchor: .center)
                    }
                }
            }

            Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(isUnlocked ? DeferTheme.success : DeferTheme.textMuted.opacity(0.86))
                .padding(.top, 2)
        }
        .padding(DeferTheme.spacing(1.75))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isUnlocked
                            ? [Color.white.opacity(0.11), Color.white.opacity(0.06)]
                            : [Color.white.opacity(0.08), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(DeferTheme.cardStroke.opacity(isUnlocked ? 1 : 0.6), lineWidth: 1)
                )
        )
    }
}

private extension AchievementRule {
    func progressValue(using progress: AchievementProgress) -> (current: Int, target: Int) {
        switch self {
        case .minCompletions(let target):
            return (min(progress.completionCount, target), target)
        case .minStreak(let target):
            return (min(progress.maxStreak, target), target)
        case .categoryMastery(let target):
            return (min(progress.highestCategoryCompletionCount, target), target)
        case .consecutiveCompletions(let target):
            return (min(progress.maxConsecutiveCompletions, target), target)
        }
    }
}
