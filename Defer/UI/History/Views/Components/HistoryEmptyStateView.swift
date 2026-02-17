import SwiftUI

struct HistoryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 44))
                .foregroundStyle(DeferTheme.textPrimary)
            Text("No completions yet")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)
            Text("Your completed defers will appear here with timeline stats.")
                .font(.subheadline)
                .foregroundStyle(DeferTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .glassCard()
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        HistoryEmptyStateView().padding()
    }
}
