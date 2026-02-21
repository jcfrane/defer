import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query(sort: \Achievement.unlockedAt, order: .reverse)
    private var unlockedAchievements: [Achievement]

    @Query(sort: \CompletionHistory.completedAt)
    private var decisions: [CompletionHistory]

    @Query(sort: \DeferItem.updatedAt)
    private var defers: [DeferItem]

    @Query(sort: \UrgeLog.loggedAt)
    private var urgeLogs: [UrgeLog]

    @StateObject private var viewModel = AchievementsViewModel()

    private var unlockedByKey: [String: Achievement] {
        viewModel.unlockedByKey(from: unlockedAchievements)
    }

    private var progress: AchievementProgress {
        viewModel.progress(defers: defers, decisions: decisions, urgeLogs: urgeLogs)
    }

    private var unlockedDefinitions: [AchievementDefinition] {
        viewModel.unlockedDefinitions(from: unlockedByKey)
    }

    private var lockedDefinitions: [AchievementDefinition] {
        viewModel.lockedDefinitions(from: unlockedByKey)
    }

    private var completionRatio: Double {
        viewModel.completionRatio(unlockedCount: unlockedAchievements.count)
    }

    private var showcasedDefinition: AchievementDefinition? {
        viewModel.showcasedDefinition()
    }

    private var showcasedAchievement: Achievement? {
        viewModel.showcasedAchievement(in: unlockedByKey)
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
                        )

                        AchievementSummaryCardView(
                            unlockedCount: unlockedAchievements.count,
                            totalCount: AchievementCatalog.all.count,
                            completionRatio: completionRatio,
                            summaryTitle: viewModel.summaryTitle(unlockedCount: unlockedAchievements.count),
                            summarySubtitle: viewModel.summarySubtitle(unlockedCount: unlockedAchievements.count, progress: progress)
                        )

                        if !unlockedDefinitions.isEmpty {
                            AchievementSectionHeaderView(
                                title: "Unlocked",
                                subtitle: "\(unlockedDefinitions.count) collected",
                                icon: "sparkles",
                                iconColor: DeferTheme.success
                            )

                            Text("Tap any badge to preview it in the center. Drag to rotate.")
                                .font(.caption)
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            badgeGrid(definitions: unlockedDefinitions)
                        }

                        if !lockedDefinitions.isEmpty {
                            AchievementSectionHeaderView(
                                title: "In Progress",
                                subtitle: "\(lockedDefinitions.count) to go",
                                icon: "lock.fill",
                                iconColor: DeferTheme.warning
                            )

                            badgeGrid(definitions: lockedDefinitions)
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 84)
                }

                if let showcasedDefinition {
                    AchievementShowcaseOverlay(
                        definition: showcasedDefinition,
                        unlocked: showcasedAchievement,
                        onDismiss: viewModel.dismissShowcase
                    )
                    .zIndex(20)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.showcasedBadgeKey)
    }

    private func badgeGrid(definitions: [AchievementDefinition]) -> some View {
        LazyVGrid(columns: viewModel.badgeColumns, spacing: DeferTheme.spacing(1.25)) {
            ForEach(definitions) { definition in
                AchievementBadgeTile(
                    definition: definition,
                    unlocked: unlockedByKey[definition.key],
                    progress: progress
                ) {
                    viewModel.showBadge(definition.key)
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
                            Color(red: 0.36, green: 0.18, blue: 0.94).opacity(0.33),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: 170, y: -280)
                .blur(radius: 10)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.08, green: 0.76, blue: 0.96).opacity(0.24),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 340, height: 340)
                .offset(x: -180, y: -150)
                .blur(radius: 9)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    AchievementsView()
        .modelContainer(PreviewFixtures.inMemoryContainerWithSeedData())
}
