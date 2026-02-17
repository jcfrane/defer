import SwiftUI

struct DeferFormSectionHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.76))
        }
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        DeferFormSectionHeaderView(title: "Goal", subtitle: "Give your defer a clear framing.")
            .padding()
    }
}
