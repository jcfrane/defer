import SwiftUI

struct SettingsInfoChipView: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.17))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.24), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        SettingsInfoChipView(icon: "clock.fill", text: "8:00 PM", color: DeferTheme.warning)
            .padding()
    }
}
