import SwiftUI

struct HomeEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass.circle")
                .font(.system(size: 44))
                .foregroundStyle(DeferTheme.textPrimary)
            Text("No active intents")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)
            Text("Add an intent to get started.")
                .font(.subheadline)
                .foregroundStyle(DeferTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .glassCard()
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeEmptyStateView()
            .padding()
    }
}
