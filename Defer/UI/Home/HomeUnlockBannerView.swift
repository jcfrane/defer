import SwiftUI

struct HomeUnlockBannerView: View {
    let newlyUnlockedCount: Int
    @State private var burstActive = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.headline)
                .symbolEffect(.bounce, value: burstActive)
            Text(
                newlyUnlockedCount == 1
                    ? "Achievement unlocked"
                    : "\(newlyUnlockedCount) achievements unlocked"
            )
            .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(DeferTheme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(DeferTheme.success.opacity(0.95)))
        .shadow(color: .black.opacity(0.22), radius: 8, y: 6)
        .onAppear {
            burstActive = true
        }
    }
}
