import SwiftUI

enum HomeVisuals {
    static func makeRandomQuoteGradient() -> [Color] {
        let palette: [Color] = [
            Color(red: 0.84, green: 0.90, blue: 0.92),
            Color(red: 0.74, green: 0.81, blue: 0.84),
            Color(red: 0.63, green: 0.71, blue: 0.76),
            Color(red: 0.82, green: 0.80, blue: 0.73),
            Color(red: 0.72, green: 0.67, blue: 0.78),
            Color(red: 0.79, green: 0.73, blue: 0.71),
            Color(red: 0.67, green: 0.73, blue: 0.70)
        ]

        let first = palette.randomElement() ?? .white
        let second = palette.randomElement() ?? .gray
        return [first, second]
    }
}
