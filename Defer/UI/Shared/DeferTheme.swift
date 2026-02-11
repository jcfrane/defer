import SwiftUI

enum DeferTheme {
    // Phase 4 palette: Growth Through Restraint
    static let forest = Color(red: 0.12, green: 0.30, blue: 0.23)  // #1F4D3A
    static let moss = Color(red: 0.44, green: 0.62, blue: 0.46)    // #6F9E76
    static let sand = Color(red: 0.92, green: 0.87, blue: 0.78)    // #EADFC8
    static let amber = Color(red: 0.84, green: 0.61, blue: 0.18)   // #D79B2E
    static let clay = Color(red: 0.71, green: 0.30, blue: 0.23)    // #B44D3A

    // Semantic tokens
    static let primary = forest
    static let surface = Color(red: 0.17, green: 0.39, blue: 0.30)
    static let success = moss
    static let warning = amber
    static let danger = clay

    static let cardBase = surface.opacity(0.72)
    static let cardStroke = sand.opacity(0.25)

    static let textPrimary = sand
    static let textMuted = sand.opacity(0.74)

    static let accent = amber
    static let tabActive = sand

    static let homeBackground = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.22, blue: 0.17),
            Color(red: 0.13, green: 0.33, blue: 0.25),
            Color(red: 0.29, green: 0.43, blue: 0.34)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCornerRadius: CGFloat = 24
    static let spacingUnit: CGFloat = 8

    static func spacing(_ units: CGFloat) -> CGFloat {
        spacingUnit * units
    }

    static func statusColor(for status: DeferStatus) -> Color {
        switch status {
        case .active: return success
        case .completed: return accent
        case .failed: return danger
        case .canceled: return sand.opacity(0.45)
        case .paused: return warning
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
            return Color(red: 0.60, green: 0.42, blue: 0.27)
        case .silver:
            return Color(red: 0.64, green: 0.69, blue: 0.72)
        case .gold:
            return amber
        case .legend:
            return Color(red: 0.45, green: 0.72, blue: 0.53)
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
                RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
                    .fill(DeferTheme.cardBase)
                    .overlay(
                        RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
                            .stroke(DeferTheme.cardStroke, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
