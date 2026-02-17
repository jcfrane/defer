import SwiftUI

struct AchievementSectionHeaderView: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
            }

            Spacer()
        }
        .padding(.top, DeferTheme.spacing(0.5))
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        AchievementSectionHeaderView(
            title: "Unlocked",
            subtitle: "3 collected",
            icon: "sparkles",
            iconColor: DeferTheme.success
        )
        .padding()
    }
}
