import SwiftUI

struct HomeQuoteCardView: View {
    let dateText: String
    let quoteText: String
    let quoteAuthor: String
    let orbGradient: [Color]
    let onDismiss: () -> Void

    var body: some View {
        HomeMotivationView(
            dateText: dateText,
            quoteText: quoteText,
            quoteAuthor: quoteAuthor,
            orbGradient: orbGradient
        )
        .padding(DeferTheme.spacing(1.75))
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary.opacity(0.9))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.22))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(DeferTheme.spacing(1))
        }
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeQuoteCardView(
            dateText: "Feb 17th",
            quoteText: "Discipline is choosing between what you want now and what you want most.",
            quoteAuthor: "Abraham Lincoln",
            orbGradient: [DeferTheme.moss, DeferTheme.sand],
            onDismiss: {}
        )
        .padding()
    }
}
