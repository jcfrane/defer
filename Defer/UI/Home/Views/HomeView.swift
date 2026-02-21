import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \DeferItem.targetDate) private var allDefers: [DeferItem]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]
    @Query(sort: \CompletionHistory.completedAt, order: .reverse) private var decisions: [CompletionHistory]
    @Query(sort: \UrgeLog.loggedAt, order: .reverse) private var urgeLogs: [UrgeLog]

    @StateObject private var viewModel = HomeViewModel()

    private var repository: DeferRepository {
        SwiftDataDeferRepository(context: modelContext)
    }

    private var pendingIntents: [DeferItem] {
        viewModel.pendingIntents(from: allDefers)
    }

    private var dueNow: [DeferItem] {
        viewModel.needsDecisionNow(from: allDefers)
    }

    private var inDelay: [DeferItem] {
        viewModel.inDelayWindow(from: allDefers)
    }

    private var stats: HomeStats {
        viewModel.stats(from: allDefers, decisions: decisions, urgeLogs: urgeLogs)
    }

    private var activeIntentIDs: [UUID] {
        pendingIntents.map(\.id)
    }

    private var whyReminderEnabled: Bool {
        AppBehaviorSettingsStore.isWhyReminderEnabled()
    }

    private var reflectionPromptEnabled: Bool {
        AppBehaviorSettingsStore.isReflectionPromptEnabled()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                homeAtmosphere

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeferTheme.spacing(2)) {
                        header

                        HomeFocusCardView(
                            stats: stats,
                            liveCount: pendingIntents.count
                        )

                        if viewModel.isQuoteCardVisible {
                            HomeQuoteCardView(
                                dateText: viewModel.quoteDateText,
                                quoteText: viewModel.quoteOfTheDay.text,
                                quoteAuthor: viewModel.quoteOfTheDay.author ?? "Unknown",
                                orbGradient: viewModel.quoteOrbGradient,
                                onDismiss: viewModel.dismissQuoteCard
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        HomeSummaryCardView(stats: stats)

                        HomeControlsRowView(
                            sortOption: $viewModel.sortOption,
                            selectedCategory: $viewModel.selectedCategory
                        )
                        .padding(DeferTheme.spacing(1.25))
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )

                        if pendingIntents.isEmpty {
                            HomeEmptyStateView()
                                .padding(.top, 24)
                        } else {
                            if !dueNow.isEmpty {
                                queueSection(title: "Due Now", subtitle: "Handle these first") {
                                    cards(for: dueNow)
                                }
                            }

                            if !inDelay.isEmpty {
                                queueSection(title: "Active", subtitle: "Defers in progress") {
                                    cards(for: inDelay)
                                }
                            }

                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $viewModel.showingCreateForm) {
                DeferFormView(mode: .create, initialDraft: .newDefault()) { draft in
                    viewModel.createIntent(draft, repository: repository)
                }
            }
            .sheet(item: $viewModel.editingDefer) { item in
                DeferFormView(mode: .edit, initialDraft: .from(item)) { draft in
                    viewModel.updateIntent(item, with: draft, repository: repository)
                }
            }
            .sheet(item: $viewModel.viewingDefer) { item in
                DeferDetailView(
                    item: item,
                    showWhyReminderPrompt: whyReminderEnabled,
                    reflectionPromptEnabled: reflectionPromptEnabled,
                    onLogUrge: {
                        viewModel.logUrge(item, repository: repository, currentAchievementCount: currentAchievementCount)
                    },
                    onUseFallback: {
                        viewModel.useFallback(item, repository: repository, currentAchievementCount: currentAchievementCount)
                    },
                    onDecideOutcome: { outcome, reflection in
                        viewModel.completeDecision(
                            item,
                            outcome: outcome,
                            reflection: reflection,
                            repository: repository,
                            currentAchievementCount: currentAchievementCount
                        )
                    },
                    onPostpone: { delayProtocol, note in
                        viewModel.postponeIntent(
                            item,
                            with: delayProtocol,
                            note: note,
                            repository: repository,
                            currentAchievementCount: currentAchievementCount
                        )
                    },
                    onMarkGaveIn: {
                        viewModel.presentDestructive(.markGaveIn, for: item)
                    },
                    onEdit: {
                        viewModel.viewingDefer = nil
                        viewModel.edit(item)
                    }
                )
            }
            .alert(
                "Enable decision reminders?",
                isPresented: $viewModel.showNotificationPermissionPrompt,
                actions: {
                    Button("Not now", role: .cancel) {
                        viewModel.dismissNotificationPermissionPrompt()
                    }
                    Button("Enable") {
                        Task {
                            await viewModel.enableContextualReminders(activeItems: pendingIntents)
                        }
                    }
                },
                message: {
                    Text("Get due reminders and follow-up nudges.")
                }
            )
            .alert(item: $viewModel.pendingDestructiveAction) { pending in
                Alert(
                    title: Text(pending.title),
                    message: Text(pending.message),
                    primaryButton: .destructive(Text(pending.confirmTitle)) {
                        viewModel.runDestructive(
                            pending,
                            repository: repository,
                            currentAchievementCount: currentAchievementCount
                        )
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.clearError()
                        }
                    }
                ),
                actions: {},
                message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
            )
            .task {
                viewModel.refreshLifecycle(repository: repository)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refreshLifecycle(repository: repository)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: pendingIntents.count)
            .animation(.easeInOut(duration: 0.2), value: viewModel.sortOption)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategory)
            .overlay(alignment: .top) {
                VStack(spacing: DeferTheme.spacing(0.75)) {
                    if let toast = viewModel.actionToast {
                        HomeActionToastView(toast: toast)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if viewModel.showAchievementCelebration {
                        HomeUnlockBannerView(newlyUnlockedCount: viewModel.newlyUnlockedCount)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, DeferTheme.spacing(1))
            }
        }
    }

    private var header: some View {
        AppPageHeaderView(
            title: viewModel.pageTitle,
            subtitle: {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                    HomeWeekdayStripView()
                }
            },
            trailing: {
                Button(action: viewModel.showCreateSheet) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DeferTheme.accent.opacity(0.95), DeferTheme.warning.opacity(0.88)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: DeferTheme.accent.opacity(0.4), radius: 10, y: 5)

                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DeferTheme.textPrimary)
                    }
                }
                .accessibilityLabel("New intent")
            }
        )
    }

    private func queueSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cards(for items: [DeferItem]) -> some View {
        LazyVStack(spacing: DeferTheme.spacing(1.5)) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HomeDeferCardView(
                    item: item,
                    showWhyReminder: whyReminderEnabled,
                    onLogUrge: {
                        viewModel.logUrge(item, repository: repository, currentAchievementCount: currentAchievementCount)
                    },
                    onUseFallback: {
                        viewModel.useFallback(item, repository: repository, currentAchievementCount: currentAchievementCount)
                    },
                    onDecideNow: {
                        viewModel.viewDetails(for: item)
                    },
                    onPostpone: {
                        viewModel.postponeIntent(
                            item,
                            with: DelayProtocol(type: .twentyFourHours),
                            note: "Postponed quickly from Home",
                            repository: repository,
                            currentAchievementCount: currentAchievementCount
                        )
                    },
                    onMarkGaveIn: {
                        viewModel.presentDestructive(.markGaveIn, for: item)
                    },
                    onCardTap: {
                        viewModel.viewDetails(for: item)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(
                    .spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.04),
                    value: activeIntentIDs
                )
                .contextMenu {
                    Button("View checkpoint") { viewModel.viewingDefer = item }
                    Button("Edit intent") { viewModel.edit(item) }
                    Button("Postpone 24h") {
                        viewModel.postponeIntent(
                            item,
                            with: DelayProtocol(type: .twentyFourHours),
                            note: "Postponed from context menu",
                            repository: repository,
                            currentAchievementCount: currentAchievementCount
                        )
                    }
                    Button("Record gave in") { viewModel.presentDestructive(.markGaveIn, for: item) }
                    Button("Cancel intent") { viewModel.presentDestructive(.cancel, for: item) }
                    Button("Delete intent", role: .destructive) {
                        viewModel.presentDestructive(.delete, for: item)
                    }
                }
            }
        }
    }

    private var homeAtmosphere: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DeferTheme.accent.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 190
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 160, y: -300)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [DeferTheme.success.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 180
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -165, y: -170)
                .blur(radius: 7)
        }
        .allowsHitTesting(false)
    }

    private func currentAchievementCount() -> Int {
        let descriptor = FetchDescriptor<Achievement>()
        return (try? modelContext.fetch(descriptor).count) ?? achievements.count
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewFixtures.inMemoryContainerWithSeedData())
}
