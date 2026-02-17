import SwiftUI

enum HomeVisuals {
    static func makeRandomQuoteGradient() -> [Color] {
        let palette: [Color] = [
            DeferTheme.moss.opacity(0.92),
            DeferTheme.sand.opacity(0.90),
            DeferTheme.amber.opacity(0.85),
            Color(red: 0.56, green: 0.73, blue: 0.54),
            Color(red: 0.46, green: 0.62, blue: 0.52)
        ]

        let first = palette.randomElement() ?? DeferTheme.moss
        let second = palette.randomElement() ?? DeferTheme.sand
        return [first, second]
    }
}
