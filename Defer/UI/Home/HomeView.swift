import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \DeferItem.targetDate) private var allDefers: [DeferItem]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]

    @State private var sortOption: HomeSortOption = .closestDate
    @State private var selectedCategory: DeferCategory?
    @State private var showingCreateForm = false
    @State private var editingDefer: DeferItem?
    @State private var pendingDestructiveAction: HomePendingDestructiveAction?
    @State private var errorMessage: String?
    @State private var showAchievementCelebration = false
    @State private var newlyUnlockedCount = 0
    @State private var quoteOrbGradient: [Color] = HomeVisuals.makeRandomQuoteGradient()

    private let motivationService = MotivationService()

    private var repository: SwiftDataDeferRepository {
        SwiftDataDeferRepository(context: modelContext)
    }

    private var activeAndOngoingDefers: [DeferItem] {
        HomeFiltering.activeAndOngoing(
            from: allDefers,
            selectedCategory: selectedCategory,
            sortOption: sortOption
        )
    }

    private var stats: HomeStats {
        HomeStats.make(from: allDefers)
    }

    private var quoteOfTheDay: DailyQuote {
        motivationService.quoteOfDay()
    }

    private var quoteDateText: String {
        let day = Calendar.current.component(.day, from: .now)
        return "\(HomeFormatting.quoteDateLabel(from: .now))\(HomeFormatting.ordinalSuffix(for: day))"
    }

    private var pageTitle: String {
        HomeFormatting.timeOfDayTitle(from: .now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        AppPageHeaderView(
                            title: pageTitle,
                            subtitle: {
                                HomeWeekdayStripView()
                            },
                            trailing: {
                                Button {
                                    showingCreateForm = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                        )

                        HomeMotivationCardView(
                            dateText: quoteDateText,
                            quoteText: quoteOfTheDay.text,
                            quoteAuthor: quoteOfTheDay.author ?? "Unknown",
                            orbGradient: quoteOrbGradient
                        )
                        HomeSummaryCardView(stats: stats)
                        HomeControlsRowView(
                            sortOption: $sortOption,
                            selectedCategory: $selectedCategory
                        )

                        if activeAndOngoingDefers.isEmpty {
                            HomeEmptyStateView()
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(activeAndOngoingDefers) { item in
                                    HomeDeferCardView(
                                        item: item,
                                        onCheckIn: { checkIn(item) },
                                        onMarkFailed: { presentDestructive(.markFailed, for: item) },
                                        onTogglePause: { togglePause(item) },
                                        onCardTap: { editingDefer = item }
                                    )
                                    .contextMenu {
                                        Button("Edit") { editingDefer = item }
                                        Button("Cancel defer") { presentDestructive(.cancel, for: item) }
                                        Button("Delete defer", role: .destructive) {
                                            presentDestructive(.delete, for: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                DeferFormView(mode: .create, initialDraft: .newDefault()) { draft in
                    createDefer(draft)
                }
            }
            .sheet(item: $editingDefer) { item in
                DeferFormView(mode: .edit, initialDraft: .from(item)) { draft in
                    updateDefer(item, with: draft)
                }
            }
            .alert(item: $pendingDestructiveAction) { pending in
                Alert(
                    title: Text(pending.title),
                    message: Text(pending.message),
                    primaryButton: .destructive(Text(pending.confirmTitle)) {
                        runDestructive(pending)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(
                "Something went wrong",
                isPresented: .init(
                    get: { errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            errorMessage = nil
                        }
                    }
                ),
                actions: {},
                message: {
                    Text(errorMessage ?? "Unknown error")
                }
            )
            .task {
                autoCompleteDefersIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    autoCompleteDefersIfNeeded()
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: activeAndOngoingDefers.count)
            .animation(.easeInOut(duration: 0.2), value: sortOption)
            .animation(.easeInOut(duration: 0.2), value: selectedCategory)
            .overlay(alignment: .top) {
                if showAchievementCelebration {
                    HomeUnlockBannerView(newlyUnlockedCount: newlyUnlockedCount)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private func createDefer(_ draft: DeferDraft) {
        do {
            _ = try repository.createDefer(
                title: draft.title,
                details: draft.details.isEmpty ? nil : draft.details,
                category: draft.category,
                type: derivedType(for: draft.category),
                startDate: draft.startDate,
                targetDate: draft.targetDate,
                strictMode: draft.strictMode
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateDefer(_ item: DeferItem, with draft: DeferDraft) {
        do {
            guard draft.targetDate > draft.startDate else {
                throw DeferRepositoryError.invalidDateRange
            }

            item.title = draft.title
            item.details = draft.details.isEmpty ? nil : draft.details
            item.category = draft.category
            item.type = derivedType(for: draft.category)
            item.startDate = draft.startDate
            item.targetDate = draft.targetDate
            item.strictMode = draft.strictMode

            try repository.updateDefer(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkIn(_ item: DeferItem) {
        let achievementCountBefore = currentAchievementCount()
        do {
            try repository.checkIn(deferItem: item, status: .success, note: nil, at: .now)
            celebrateIfNeeded(previousCount: achievementCountBefore)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func togglePause(_ item: DeferItem) {
        do {
            let targetStatus: DeferStatus = item.status == .paused ? .active : .paused
            try repository.setStatus(for: item, to: targetStatus, at: .now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func presentDestructive(_ action: HomePendingDestructiveAction.ActionType, for item: DeferItem) {
        pendingDestructiveAction = HomePendingDestructiveAction(action: action, item: item)
    }

    private func runDestructive(_ pending: HomePendingDestructiveAction) {
        do {
            switch pending.action {
            case .markFailed:
                try repository.setStatus(for: pending.item, to: .failed, at: .now)
            case .cancel:
                try repository.setStatus(for: pending.item, to: .canceled, at: .now)
            case .delete:
                try repository.deleteDefer(pending.item)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func autoCompleteDefersIfNeeded() {
        let achievementCountBefore = currentAchievementCount()
        do {
            try repository.enforceStrictModeCheckIn(asOf: .now)
            _ = try repository.autoCompleteEligibleDefers(asOf: .now)
            celebrateIfNeeded(previousCount: achievementCountBefore)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func currentAchievementCount() -> Int {
        let descriptor = FetchDescriptor<Achievement>()
        return (try? modelContext.fetch(descriptor).count) ?? achievements.count
    }

    private func celebrateIfNeeded(previousCount: Int) {
        let delta = currentAchievementCount() - previousCount
        guard delta > 0 else { return }

        newlyUnlockedCount = delta
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showAchievementCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showAchievementCelebration = false
            }
        }
    }

    private func derivedType(for category: DeferCategory) -> DeferType {
        switch category {
        case .spending:
            return .spending
        case .custom:
            return .custom
        default:
            return .abstinence
        }
    }
}
