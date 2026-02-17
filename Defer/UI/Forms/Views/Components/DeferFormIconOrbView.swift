import SwiftUI

struct DeferFormIconOrbView: View {
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
        DeferFormIconOrbView(systemName: "calendar", tint: DeferTheme.warning)
            .padding()
    }
}
