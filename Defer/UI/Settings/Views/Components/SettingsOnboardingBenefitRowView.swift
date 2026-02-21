import SwiftUI

struct SettingsOnboardingBenefitRowView: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: DeferTheme.spacing(1)) {
            SettingsIconOrbView(systemName: icon, tint: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            }

            Spacer(minLength: 0)
        }
        .padding(DeferTheme.spacing(1))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        SettingsOnboardingBenefitRowView(
            icon: "checkmark.circle.fill",
            color: DeferTheme.success,
            title: "Checkpoint due reminder",
            subtitle: "Prompt right when a decision checkpoint arrives."
        )
        .padding()
    }
}
