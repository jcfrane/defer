import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var sortOption: HomeSortOption = .checkpointSoonest
    @Published var selectedCategory: DeferCategory?
    @Published var showingCreateForm = false
    @Published var viewingDefer: DeferItem?
    @Published var editingDefer: DeferItem?
    @Published var pendingDestructiveAction: HomePendingDestructiveAction?
    @Published var errorMessage: String?
    @Published var showAchievementCelebration = false
    @Published var newlyUnlockedCount = 0
    @Published var quoteOrbGradient: [Color] = HomeVisuals.makeRandomQuoteGradient()
    @Published var isQuoteCardVisible = true
    @Published var showNotificationPermissionPrompt = false
    @Published var actionToast: HomeActionToast?

    private let motivationService: MotivationService
    private let defaults: UserDefaults
    private var actionToastDismissWorkItem: DispatchWorkItem?

    init(motivationService: MotivationService? = nil, defaults: UserDefaults = .standard) {
        self.motivationService = motivationService ?? MotivationService()
        self.defaults = defaults
    }

    var pageTitle: String {
        HomeFormatting.timeOfDayTitle(from: .now)
    }

    var quoteDateText: String {
        let day = Calendar.current.component(.day, from: .now)
        return "\(HomeFormatting.quoteDateLabel(from: .now))\(HomeFormatting.ordinalSuffix(for: day))"
    }

    var quoteOfTheDay: DailyQuote {
        motivationService.quoteOfDay()
    }

    func pendingIntents(from allDefers: [DeferItem]) -> [DeferItem] {
        HomeFiltering.pendingIntents(
            from: allDefers,
            selectedCategory: selectedCategory,
            sortOption: sortOption
        )
    }

    func needsDecisionNow(from allDefers: [DeferItem]) -> [DeferItem] {
        pendingIntents(from: allDefers).filter { $0.isCheckpointDue(referenceDate: .now) }
    }

    func inDelayWindow(from allDefers: [DeferItem]) -> [DeferItem] {
        pendingIntents(from: allDefers).filter {
            $0.status.normalizedLifecycle == .activeWait && !$0.isCheckpointDue(referenceDate: .now)
        }
    }

    func recentUrges(from urgeLogs: [UrgeLog], limit: Int = 5) -> [UrgeLog] {
        Array(urgeLogs.sorted(by: { $0.loggedAt > $1.loggedAt }).prefix(max(0, limit)))
    }

    func stats(from allDefers: [DeferItem], decisions: [CompletionHistory], urgeLogs: [UrgeLog]) -> HomeStats {
        HomeStats.make(from: allDefers, decisions: decisions, urgeLogs: urgeLogs)
    }

    func dismissQuoteCard() {
        AppHaptics.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            isQuoteCardVisible = false
        }
    }

    func showCreateSheet() {
        showingCreateForm = true
    }

    func viewDetails(for item: DeferItem) {
        AppHaptics.selection()
        viewingDefer = item
    }

    func edit(_ item: DeferItem) {
        editingDefer = item
    }

    func presentDestructive(_ action: HomePendingDestructiveAction.ActionType, for item: DeferItem) {
        pendingDestructiveAction = HomePendingDestructiveAction(action: action, item: item)
    }

    @discardableResult
    func createIntent(_ draft: DeferDraft, repository: DeferRepository) -> DeferItem? {
        do {
            let created = try repository.captureIntent(
                title: draft.title,
                whyItMatters: draft.whyItMatters,
                category: draft.category,
                type: derivedType(for: draft.category),
                estimatedCost: draft.estimatedCost,
                delayProtocol: draft.delayProtocol,
                fallbackAction: draft.fallbackAction,
                capturedAt: draft.startDate
            )

            Task {
                await maybePresentNotificationPromptAfterCreate(for: created)
            }

            return created
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func updateIntent(_ item: DeferItem, with draft: DeferDraft, repository: DeferRepository) {
        do {
            item.title = draft.title
            item.whyItMatters = draft.whyItMatters
            item.details = draft.whyItMatters
            item.category = draft.category
            item.type = derivedType(for: draft.category)
            item.startDate = draft.startDate
            item.targetDate = draft.delayProtocol.decisionDate(from: draft.startDate)
            item.delayProtocolType = draft.delayProtocol.type
            item.delayDurationHours = draft.delayProtocol.durationHours
            item.estimatedCost = draft.estimatedCost
            item.fallbackAction = draft.fallbackAction

            try repository.updateIntent(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshLifecycle(repository: DeferRepository) {
        do {
            _ = try repository.refreshLifecycle(asOf: .now)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logUrge(_ item: DeferItem, intensity: Int = 3, note: String? = nil, repository: DeferRepository, currentAchievementCount: @escaping () -> Int) {
        let achievementCountBefore = currentAchievementCount()

        do {
            try repository.logUrge(intent: item, intensity: intensity, note: note, usedFallbackAction: false, at: .now)
            AppHaptics.impact(.light)
            showActionToast(.urgeLogged)
            celebrateIfNeeded(previousCount: achievementCountBefore, currentAchievementCount: currentAchievementCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func useFallback(_ item: DeferItem, repository: DeferRepository, currentAchievementCount: @escaping () -> Int) {
        let achievementCountBefore = currentAchievementCount()

        do {
            let note = item.fallbackAction?.isEmpty == false ? "Used fallback: \(item.fallbackAction ?? "")" : "Used fallback action"
            try repository.logUrge(intent: item, intensity: 4, note: note, usedFallbackAction: true, at: .now)
            AppHaptics.success()
            showActionToast(.fallbackUsed)
            celebrateIfNeeded(previousCount: achievementCountBefore, currentAchievementCount: currentAchievementCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteUrgeLog(_ log: UrgeLog, repository: DeferRepository) {
        do {
            try repository.deleteUrgeLog(log)
            AppHaptics.impact(.light)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeDecision(
        _ item: DeferItem,
        outcome: DecisionOutcome,
        reflection: String? = nil,
        repository: DeferRepository,
        currentAchievementCount: @escaping () -> Int
    ) {
        let achievementCountBefore = currentAchievementCount()

        do {
            try repository.completeDecision(
                intent: item,
                outcome: outcome,
                reflection: reflection,
                urgeScore: nil,
                regretScore: nil,
                at: .now
            )
            AppHaptics.success()
            celebrateIfNeeded(previousCount: achievementCountBefore, currentAchievementCount: currentAchievementCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func postponeIntent(
        _ item: DeferItem,
        with delayProtocol: DelayProtocol,
        note: String? = nil,
        repository: DeferRepository,
        currentAchievementCount: @escaping () -> Int
    ) {
        let achievementCountBefore = currentAchievementCount()

        do {
            try repository.postponeDecision(intent: item, delayProtocol: delayProtocol, note: note, at: .now)
            AppHaptics.impact(.soft)
            celebrateIfNeeded(previousCount: achievementCountBefore, currentAchievementCount: currentAchievementCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runDestructive(
        _ pending: HomePendingDestructiveAction,
        repository: DeferRepository,
        currentAchievementCount: @escaping () -> Int
    ) {
        do {
            switch pending.action {
            case .markGaveIn:
                completeDecision(
                    pending.item,
                    outcome: .gaveIn,
                    reflection: nil,
                    repository: repository,
                    currentAchievementCount: currentAchievementCount
                )
            case .cancel:
                completeDecision(
                    pending.item,
                    outcome: .canceled,
                    reflection: nil,
                    repository: repository,
                    currentAchievementCount: currentAchievementCount
                )
            case .delete:
                try repository.deleteDefer(pending.item)
                AppHaptics.impact(.medium)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func dismissNotificationPermissionPrompt() {
        showNotificationPermissionPrompt = false
    }

    func enableContextualReminders(activeItems: [DeferItem]) async {
        let authorizationState = await LocalNotificationManager.requestAuthorizationIfNeeded()

        if authorizationState == .enabled {
            NotificationSettingsStore.enableRecommendedDefaults(defaults: defaults)
            let preferences = NotificationSettingsStore.loadPreferences(defaults: defaults)
            await LocalNotificationManager.syncNotifications(
                preferences: preferences,
                activeItems: activeItems
            )
            await MainActor.run {
                AppHaptics.success()
                showNotificationPermissionPrompt = false
            }
        } else {
            await MainActor.run {
                AppHaptics.warning()
                showNotificationPermissionPrompt = false
            }
        }
    }

    private func celebrateIfNeeded(
        previousCount: Int,
        currentAchievementCount: @escaping () -> Int
    ) {
        let delta = currentAchievementCount() - previousCount
        guard delta > 0 else { return }

        newlyUnlockedCount = delta
        AppHaptics.success()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showAchievementCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                self.showAchievementCelebration = false
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

    private func maybePresentNotificationPromptAfterCreate(for created: DeferItem) async {
        guard created.status.normalizedLifecycle == .activeWait else { return }
        guard !NotificationSettingsStore.hasShownContextualPrompt(defaults: defaults) else { return }

        let state = await LocalNotificationManager.authorizationState()
        guard state == .notDetermined else { return }

        NotificationSettingsStore.markContextualPromptShown(defaults: defaults)
        await MainActor.run {
            showNotificationPermissionPrompt = true
        }
    }

    private func showActionToast(_ kind: HomeActionToastKind) {
        actionToastDismissWorkItem?.cancel()

        let toast = HomeActionToast(kind: kind)
        withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
            actionToast = toast
        }

        let dismissWorkItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                if self.actionToast?.id == toast.id {
                    self.actionToast = nil
                }
            }
        }

        actionToastDismissWorkItem = dismissWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: dismissWorkItem)
    }
}
