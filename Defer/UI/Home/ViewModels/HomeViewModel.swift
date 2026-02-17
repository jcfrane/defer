import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var sortOption: HomeSortOption = .closestDate
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

    private let motivationService: MotivationService

    init(motivationService: MotivationService? = nil) {
        self.motivationService = motivationService ?? MotivationService()
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

    func activeAndOngoingDefers(from allDefers: [DeferItem]) -> [DeferItem] {
        HomeFiltering.activeAndOngoing(
            from: allDefers,
            selectedCategory: selectedCategory,
            sortOption: sortOption
        )
    }

    func stats(from allDefers: [DeferItem]) -> HomeStats {
        HomeStats.make(from: allDefers)
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

    func createDefer(_ draft: DeferDraft, repository: DeferRepository) {
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

    func updateDefer(_ item: DeferItem, with draft: DeferDraft, repository: DeferRepository) {
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

    func checkIn(
        _ item: DeferItem,
        repository: DeferRepository,
        currentAchievementCount: @escaping () -> Int
    ) {
        let achievementCountBefore = currentAchievementCount()

        do {
            try repository.checkIn(deferItem: item, status: .success, note: nil, at: .now)
            AppHaptics.impact(.light)
            celebrateIfNeeded(previousCount: achievementCountBefore, currentAchievementCount: currentAchievementCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePause(_ item: DeferItem, repository: DeferRepository) {
        do {
            let targetStatus: DeferStatus = item.status == .paused ? .active : .paused
            try repository.setStatus(for: item, to: targetStatus, at: .now)
            AppHaptics.impact(.soft)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func runDestructive(_ pending: HomePendingDestructiveAction, repository: DeferRepository) {
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

    func autoCompleteDefersIfNeeded(
        repository: DeferRepository,
        currentAchievementCount: @escaping () -> Int
    ) {
        let achievementCountBefore = currentAchievementCount()

        do {
            _ = try repository.autoCheckInNonStrictDefers(asOf: .now)
            try repository.enforceStrictModeCheckIn(asOf: .now)
            let completedCount = try repository.autoCompleteEligibleDefers(asOf: .now)
            if completedCount > 0 {
                AppHaptics.success()
            }
            celebrateIfNeeded(previousCount: achievementCountBefore, currentAchievementCount: currentAchievementCount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
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
}
