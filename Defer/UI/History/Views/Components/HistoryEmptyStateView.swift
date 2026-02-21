import SwiftUI

struct HistoryEmptyStateView: View {
    var body: some View {
        VStack(spacing: DeferTheme.spacing(1.75)) {
            ZStack {
                Circle()
                    .fill(DeferTheme.warning.opacity(0.2))
                    .frame(width: 96, height: 96)

                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .frame(width: 110, height: 110)

                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
            }

            VStack(spacing: DeferTheme.spacing(0.75)) {
                Text("Your timeline starts with one finish")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Decision outcomes will appear here with category patterns and intentionality trends.")
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DeferTheme.spacing(2))
        .padding(.vertical, DeferTheme.spacing(3))
        .background(
            RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [DeferTheme.surface.opacity(0.84), DeferTheme.surface.opacity(0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DeferTheme.cardCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 10)
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()

        HistoryEmptyStateView()
            .padding()
    }
}
