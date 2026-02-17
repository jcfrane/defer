import Foundation
import Combine
import SwiftUI

@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published var showcasedBadgeKey: String?

    var badgeColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: DeferTheme.spacing(1.25), alignment: .top)]
    }

    func unlockedByKey(from unlockedAchievements: [Achievement]) -> [String: Achievement] {
        Dictionary(uniqueKeysWithValues: unlockedAchievements.map { ($0.key, $0) })
    }

    func progress(defers: [DeferItem], completions: [CompletionHistory]) -> AchievementProgress {
        AchievementProgress.from(defers: defers, completions: completions)
    }

    func unlockedDefinitions(from unlockedByKey: [String: Achievement]) -> [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedByKey[$0.key] != nil }
    }

    func lockedDefinitions(from unlockedByKey: [String: Achievement]) -> [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedByKey[$0.key] == nil }
    }

    func completionRatio(unlockedCount: Int) -> Double {
        guard !AchievementCatalog.all.isEmpty else { return 0 }
        return Double(unlockedCount) / Double(AchievementCatalog.all.count)
    }

    func showcasedDefinition() -> AchievementDefinition? {
        guard let showcasedBadgeKey else { return nil }
        return AchievementCatalog.definition(for: showcasedBadgeKey)
    }

    func showcasedAchievement(in unlockedByKey: [String: Achievement]) -> Achievement? {
        guard let showcasedBadgeKey else { return nil }
        return unlockedByKey[showcasedBadgeKey]
    }

    func summaryTitle(unlockedCount: Int) -> String {
        if unlockedCount == 0 {
            return "Your first badge is waiting"
        }

        if unlockedCount == AchievementCatalog.all.count {
            return "Full collection complete"
        }

        return "Collection is growing steadily"
    }

    func summarySubtitle(unlockedCount: Int, progress: AchievementProgress) -> String {
        if unlockedCount == 0 {
            return "Complete your first defer to unlock your first achievement."
        }

        return "\(progress.completionCount) completions and a best streak of \(progress.maxStreak) days."
    }

    func showBadge(_ key: String) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) {
            showcasedBadgeKey = key
        }
    }

    func dismissShowcase() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            showcasedBadgeKey = nil
        }
    }
}
