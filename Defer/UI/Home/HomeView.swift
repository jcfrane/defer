import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \DeferItem.targetDate) private var allDefers: [DeferItem]
    @Query(sort: \Achievement.unlockedAt, order: .reverse) private var achievements: [Achievement]

    @State private var sortOption: HomeSortOption = .closestDate
    @State private var selectedCategory: DeferCategory?
    @State private var showingCreateForm = false
    @State private var viewingDefer: DeferItem?
    @State private var editingDefer: DeferItem?
    @State private var pendingDestructiveAction: HomePendingDestructiveAction?
    @State private var errorMessage: String?
    @State private var showAchievementCelebration = false
    @State private var newlyUnlockedCount = 0
    @State private var quoteOrbGradient: [Color] = HomeVisuals.makeRandomQuoteGradient()
    @State private var isQuoteCardVisible = true

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
                        AppPageHeaderView(
                            title: pageTitle,
                            subtitle: {
                                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                                    HomeWeekdayStripView()
                                    Text("Move one step with intention today.")
                                        .font(.caption)
                                        .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                                }
                            },
                            trailing: {
                                Button {
                                    showingCreateForm = true
                                } label: {
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

                        homeFocusCard

                        if isQuoteCardVisible {
                            HomeMotivationView(
                                dateText: quoteDateText,
                                quoteText: quoteOfTheDay.text,
                                quoteAuthor: quoteOfTheDay.author ?? "Unknown",
                                orbGradient: quoteOrbGradient
                            )
                            .padding(DeferTheme.spacing(1.75))
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.09))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                    )
                            )
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    AppHaptics.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isQuoteCardVisible = false
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(DeferTheme.textPrimary.opacity(0.9))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.22))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(DeferTheme.spacing(1))
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        HomeSummaryCardView(stats: stats)

                        HomeControlsRowView(
                            sortOption: $sortOption,
                            selectedCategory: $selectedCategory
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
                            LazyVStack(spacing: DeferTheme.spacing(1.5)) {
                                ForEach(Array(activeAndOngoingDefers.enumerated()), id: \.element.id) { index, item in
                                    HomeDeferCardView(
                                        item: item,
                                        onCheckIn: { checkIn(item) },
                                        onMarkFailed: { presentDestructive(.markFailed, for: item) },
                                        onTogglePause: { togglePause(item) },
                                        onCardTap: {
                                            AppHaptics.selection()
                                            viewingDefer = item
                                        }
                                    )
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .animation(
                                        .spring(response: 0.45, dampingFraction: 0.82).delay(Double(index) * 0.04),
                                        value: activeDeferIDs
                                    )
                                    .contextMenu {
                                        Button("View details") { viewingDefer = item }
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
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
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
            .sheet(item: $viewingDefer) { item in
                DeferDetailView(
                    item: item,
                    onCheckIn: { checkIn(item) },
                    onTogglePause: { togglePause(item) },
                    onMarkFailed: { presentDestructive(.markFailed, for: item) },
                    onEdit: {
                        viewingDefer = nil
                        editingDefer = item
                    }
                )
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
                        .padding(.top, DeferTheme.spacing(1))
                        .transition(.move(edge: .top).combined(with: .opacity))
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

    private var homeFocusCard: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Focus Pulse")
                    .font(.caption.weight(.semibold))
                    .tracking(0.7)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.72))

                Text(homePulseTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(homePulseSubtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    .lineLimit(2)

                HStack(spacing: DeferTheme.spacing(0.75)) {
                    homeChip(icon: "target", text: "\(stats.active) active", color: DeferTheme.success)
                    homeChip(icon: "clock.fill", text: "\(stats.dueSoon) due soon", color: DeferTheme.warning)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DeferTheme.success.opacity(0.95),
                                DeferTheme.moss.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: DeferTheme.success.opacity(0.34), radius: 14, y: 6)

                VStack(spacing: 2) {
                    Text("\(activeAndOngoingDefers.count)")
                        .font(.title3.weight(.bold))
                    Text("live")
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(0.7)
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

    private var homePulseTitle: String {
        if stats.active == 0 {
            return "Fresh slate, ready to begin"
        }

        if stats.dueSoon > 0 {
            return "Keep pressure low, momentum high"
        }

        return "Strong rhythm this week"
    }

    private var homePulseSubtitle: String {
        if stats.active == 0 {
            return "Create a new defer and start your next intentional streak."
        }

        if stats.dueSoon > 0 {
            return "A few goals are nearing target dates. Stay locked in."
        }

        return "Your active goals are paced well. Keep your streaks protected."
    }

    private func homeChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(DeferTheme.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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
            AppHaptics.impact(.light)
            celebrateIfNeeded(previousCount: achievementCountBefore)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func togglePause(_ item: DeferItem) {
        do {
            let targetStatus: DeferStatus = item.status == .paused ? .active : .paused
            try repository.setStatus(for: item, to: targetStatus, at: .now)
            AppHaptics.impact(.soft)
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
                AppHaptics.warning()
            case .cancel:
                try repository.setStatus(for: pending.item, to: .canceled, at: .now)
                AppHaptics.warning()
            case .delete:
                try repository.deleteDefer(pending.item)
                AppHaptics.impact(.medium)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func autoCompleteDefersIfNeeded() {
        let achievementCountBefore = currentAchievementCount()
        do {
            try repository.enforceStrictModeCheckIn(asOf: .now)
            let completedCount = try repository.autoCompleteEligibleDefers(asOf: .now)
            if completedCount > 0 {
                AppHaptics.success()
            }
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
        AppHaptics.success()

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
