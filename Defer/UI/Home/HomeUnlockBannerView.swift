import SwiftUI

struct HomeUnlockBannerView: View {
    let newlyUnlockedCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.headline)
            Text(
                newlyUnlockedCount == 1
                    ? "Achievement unlocked"
                    : "\(newlyUnlockedCount) achievements unlocked"
            )
            .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(DeferTheme.success.opacity(0.95)))
        .shadow(color: .black.opacity(0.22), radius: 8, y: 6)
    }
}
