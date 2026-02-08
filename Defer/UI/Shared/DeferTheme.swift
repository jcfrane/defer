import SwiftUI

enum DeferTheme {
    static let backgroundTop = Color(red: 0.06, green: 0.12, blue: 0.24)
    static let backgroundBottom = Color(red: 0.79, green: 0.87, blue: 0.98)

    static let cardBase = Color.white.opacity(0.16)
    static let cardStroke = Color.white.opacity(0.24)

    static let primary = Color(red: 0.16, green: 0.41, blue: 0.86)
    static let primaryDark = Color(red: 0.09, green: 0.24, blue: 0.58)
    static let tabActive = Color(red: 0.92, green: 0.97, blue: 1.00)
    static let accent = Color(red: 0.23, green: 0.74, blue: 0.91)
    static let success = Color(red: 0.22, green: 0.65, blue: 0.37)
    static let danger = Color(red: 0.70, green: 0.30, blue: 0.23)

    static let textPrimary = Color.white
    static let textMuted = Color.white.opacity(0.7)

    static let homeBackground = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func statusColor(for status: DeferStatus) -> Color {
        switch status {
        case .active: return success
        case .completed: return accent
        case .failed: return danger
        case .canceled: return .gray
        case .paused: return .orange
        }
    }

    static func categoryIcon(for category: DeferCategory) -> String {
        switch category {
        case .health: return "heart.fill"
        case .spending: return "creditcard.fill"
        case .nutrition: return "leaf.fill"
        case .habit: return "sparkles"
        case .relationship: return "person.2.fill"
        case .productivity: return "bolt.fill"
        case .custom: return "target"
        }
    }

    static func badgeColor(for tier: AchievementTier) -> Color {
        switch tier {
        case .bronze:
            return Color(red: 0.63, green: 0.44, blue: 0.28)
        case .silver:
            return Color(red: 0.62, green: 0.67, blue: 0.75)
        case .gold:
            return Color(red: 0.86, green: 0.67, blue: 0.20)
        case .legend:
            return Color(red: 0.56, green: 0.40, blue: 0.92)
        }
    }

    static func badgeGradient(for tier: AchievementTier) -> LinearGradient {
        let base = badgeColor(for: tier)
        return LinearGradient(
            colors: [base.opacity(0.8), base],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(DeferTheme.cardBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(DeferTheme.cardStroke, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.14), radius: 18, y: 10)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
