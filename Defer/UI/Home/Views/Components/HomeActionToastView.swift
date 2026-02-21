import SwiftUI

struct HomeActionToastView: View {
    let toast: HomeActionToast

    private var tint: Color {
        switch toast.kind {
        case .urgeLogged:
            return DeferTheme.success
        case .fallbackUsed:
            return DeferTheme.accent
        }
    }

    var body: some View {
        HStack(spacing: DeferTheme.spacing(0.9)) {
            Image(systemName: toast.kind.icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.kind.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(toast.kind.detail)
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textPrimary.opacity(0.92))
            }
        }
        .padding(.horizontal, DeferTheme.spacing(1.5))
        .padding(.vertical, DeferTheme.spacing(1.1))
        .background(
            Capsule()
                .fill(tint.opacity(0.96))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 10, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(toast.kind.title). \(toast.kind.detail)")
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        VStack(spacing: DeferTheme.spacing(1)) {
            HomeActionToastView(toast: HomeActionToast(kind: .urgeLogged))
            HomeActionToastView(toast: HomeActionToast(kind: .fallbackUsed))
        }
        .padding()
    }
}
