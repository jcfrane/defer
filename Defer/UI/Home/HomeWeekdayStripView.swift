import SwiftUI

struct HomeWeekdayStripView: View {
    private let weekdayLetters = HomeFormatting.weekdayLetters()
    private let currentWeekdayIndex = HomeFormatting.currentWeekdayIndex()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(weekdayLetters.enumerated()), id: \.offset) { index, letter in
                Text(letter)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(index == currentWeekdayIndex ? .white : DeferTheme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(index == currentWeekdayIndex ? Color.white.opacity(0.22) : Color.clear)
                    )
            }
        }
    }
}
