import SwiftUI

struct HomeGrowthTreeView: View {
    let intentionalRate: Double

    @State private var pulse = false

    private var stage: Int {
        switch intentionalRate {
        case 0.8...:
            return 3
        case 0.6...:
            return 2
        case 0.35...:
            return 1
        default:
            return 0
        }
    }

    private var treeScale: CGFloat {
        [0.8, 0.95, 1.08, 1.2][stage]
    }

    private var ringScale: CGFloat {
        pulse ? 1.15 : 0.86
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [DeferTheme.success.opacity(0.95), DeferTheme.moss.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)

            Circle()
                .stroke(Color.white.opacity(0.36), lineWidth: 1.5)
                .frame(width: 72, height: 72)
                .scaleEffect(ringScale)
                .opacity(pulse ? 0.3 : 0.7)

            Image(systemName: stage >= 2 ? "leaf.arrow.circlepath" : "leaf.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(DeferTheme.textPrimary)
                .scaleEffect(treeScale)
        }
        .shadow(color: DeferTheme.success.opacity(0.36), radius: 14, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HStack(spacing: 20) {
            HomeGrowthTreeView(intentionalRate: 0.12)
            HomeGrowthTreeView(intentionalRate: 0.42)
            HomeGrowthTreeView(intentionalRate: 0.66)
            HomeGrowthTreeView(intentionalRate: 0.9)
        }
        .padding()
    }
}
