import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \DeferItem.targetDate) private var allDefers: [DeferItem]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]

    @StateObject private var viewModel = HomeViewModel()

    private var repository: DeferRepository {
        SwiftDataDeferRepository(context: modelContext)
    }

    private var activeAndOngoingDefers: [DeferItem] {
        viewModel.activeAndOngoingDefers(from: allDefers)
    }

    private var stats: HomeStats {
        viewModel.stats(from: allDefers)
    }

    private var activeDeferIDs: [UUID] {
        activeAndOngoingDefers.map(\.id)
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
                            liveCount: activeAndOngoingDefers.count
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

                        if activeAndOngoingDefers.isEmpty {
                            HomeEmptyStateView()
                                .padding(.top, 40)
                        } else {
                            deferCards
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $viewModel.showingCreateForm) {
                DeferFormView(mode: .create, initialDraft: .newDefault()) { draft in
                    viewModel.createDefer(draft, repository: repository)
                }
            }
            .sheet(item: $viewModel.editingDefer) { item in
                DeferFormView(mode: .edit, initialDraft: .from(item)) { draft in
                    viewModel.updateDefer(item, with: draft, repository: repository)
                }
            }
            .sheet(item: $viewModel.viewingDefer) { item in
                DeferDetailView(
                    item: item,
                    onCheckIn: {
                        viewModel.checkIn(item, repository: repository, currentAchievementCount: currentAchievementCount)
                    },
                    onTogglePause: {
                        viewModel.togglePause(item, repository: repository)
                    },
                    onMarkFailed: {
                        viewModel.presentDestructive(.markFailed, for: item)
                    },
                    onEdit: {
                        viewModel.viewingDefer = nil
                        viewModel.edit(item)
                    }
                )
            }
            .alert(item: $viewModel.pendingDestructiveAction) { pending in
                Alert(
                    title: Text(pending.title),
                    message: Text(pending.message),
                    primaryButton: .destructive(Text(pending.confirmTitle)) {
                        viewModel.runDestructive(pending, repository: repository)
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
                viewModel.autoCompleteDefersIfNeeded(
                    repository: repository,
                    currentAchievementCount: currentAchievementCount
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.autoCompleteDefersIfNeeded(
                        repository: repository,
                        currentAchievementCount: currentAchievementCount
                    )
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: activeAndOngoingDefers.count)
            .animation(.easeInOut(duration: 0.2), value: viewModel.sortOption)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategory)
            .overlay(alignment: .top) {
                if viewModel.showAchievementCelebration {
                    HomeUnlockBannerView(newlyUnlockedCount: viewModel.newlyUnlockedCount)
                        .padding(.top, DeferTheme.spacing(1))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var header: some View {
        AppPageHeaderView(
            title: viewModel.pageTitle,
            subtitle: {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                    HomeWeekdayStripView()
                    Text("Move one step with intention today.")
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                }
            },
            trailing: {
                Button(action: viewModel.showCreateSheet) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DeferTheme.accent.opacity(0.95),
                                        DeferTheme.warning.opacity(0.88)
                                    ],
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
            }
        )
    }

    private var deferCards: some View {
        LazyVStack(spacing: DeferTheme.spacing(1.5)) {
            ForEach(Array(activeAndOngoingDefers.enumerated()), id: \.element.id) { index, item in
                HomeDeferCardView(
                    item: item,
                    onCheckIn: {
                        viewModel.checkIn(item, repository: repository, currentAchievementCount: currentAchievementCount)
                    },
                    onMarkFailed: {
                        viewModel.presentDestructive(.markFailed, for: item)
                    },
                    onTogglePause: {
                        viewModel.togglePause(item, repository: repository)
                    },
                    onCardTap: {
                        viewModel.viewDetails(for: item)
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(
                    .spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.04),
                    value: activeDeferIDs
                )
                .contextMenu {
                    Button("View details") { viewModel.viewingDefer = item }
                    Button("Edit") { viewModel.edit(item) }
                    Button("Cancel defer") { viewModel.presentDestructive(.cancel, for: item) }
                    Button("Delete defer", role: .destructive) {
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
                .offset(x: 160, y: -300)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.success.opacity(0.18),
                            .clear
                        ],
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
