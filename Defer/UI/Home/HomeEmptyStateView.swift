import SwiftUI

struct HomeEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.9))
            Text("No ongoing defers")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Create your first defer and start building your streak.")
                .font(.subheadline)
                .foregroundStyle(DeferTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .glassCard()
    }
}
