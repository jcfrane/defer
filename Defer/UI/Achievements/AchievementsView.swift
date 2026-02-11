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

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DeferTheme.spacing(1.75)) {
                        AppPageHeaderView(title: "Achievements")

                        summaryCard

                        ForEach(AchievementCatalog.all) { definition in
                            AchievementBadgeCard(
                                definition: definition,
                                unlocked: unlockedByKey[definition.key],
                                progress: progress
                            )
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress Gallery")
                .font(.title3.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)

            HStack(spacing: 12) {
                statBlock(title: "Unlocked", value: "\(unlockedAchievements.count)", icon: "rosette")
                statBlock(title: "Completions", value: "\(progress.completionCount)", icon: "checkmark.circle")
                statBlock(title: "Best Streak", value: "\(progress.maxStreak)", icon: "flame")
            }
        }
        .padding(18)
        .glassCard()
    }

    private func statBlock(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
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
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DeferTheme.surface.opacity(0.65)))
    }
}

private struct AchievementBadgeCard: View {
    let definition: AchievementDefinition
    let unlocked: Achievement?
    let progress: AchievementProgress

    private var isUnlocked: Bool { unlocked != nil }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DeferTheme.badgeGradient(for: definition.tier))
                    .frame(width: 48, height: 48)
                    .opacity(isUnlocked ? 1 : 0.35)

                Image(systemName: definition.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .symbolEffect(.bounce, value: isUnlocked)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(definition.title)
                        .font(.headline)
                        .foregroundStyle(DeferTheme.textPrimary)

                    Spacer()

                    Text(definition.tier.displayName)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(DeferTheme.badgeColor(for: definition.tier).opacity(0.9)))
                        .foregroundStyle(DeferTheme.textPrimary)
                }

                Text(definition.details)
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted)

                if let unlocked {
                    Text("Unlocked \(unlocked.unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted)
                } else {
                    Text(definition.rule.progressText(using: progress))
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted)
                }
            }

            Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(isUnlocked ? DeferTheme.success : DeferTheme.textMuted)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(DeferTheme.surface.opacity(0.65)))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DeferTheme.cardStroke.opacity(isUnlocked ? 1 : 0.7), lineWidth: 1)
        )
    }
}
