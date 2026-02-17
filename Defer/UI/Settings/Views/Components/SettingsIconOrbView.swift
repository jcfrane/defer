import SwiftUI

struct SettingsIconOrbView: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.callout.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(tint.opacity(0.18))
            )
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        SettingsIconOrbView(systemName: "bell.fill", tint: DeferTheme.accent)
            .padding()
    }
}
