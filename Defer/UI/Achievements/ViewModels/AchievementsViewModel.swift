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

    func progress(defers: [DeferItem], decisions: [CompletionHistory], urgeLogs: [UrgeLog]) -> AchievementProgress {
        AchievementProgress.from(defers: defers, completions: decisions, urgeLogs: urgeLogs)
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
            return "Your first decision-quality badge is waiting"
        }

        if unlockedCount == AchievementCatalog.all.count {
            return "Full collection complete"
        }

        return "Behavior-quality collection growing"
    }

    func summarySubtitle(unlockedCount: Int, progress: AchievementProgress) -> String {
        if unlockedCount == 0 {
            return "Resolve one intent intentionally to unlock the first badge."
        }

        let intentionalRate = progress.resolvedCount == 0
            ? 0
            : Int((Double(progress.intentionalCount) / Double(progress.resolvedCount) * 100).rounded())

        return "\(progress.intentionalCount) intentional outcomes, \(intentionalRate)% intentional rate."
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
