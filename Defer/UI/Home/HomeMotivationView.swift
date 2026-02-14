import SwiftUI

struct HomeMotivationView: View {
    let dateText: String
    let quoteText: String
    let quoteAuthor: String
    let orbGradient: [Color]

    @State private var quoteOrbDrift = false

    var body: some View {
        HStack(alignment: .center, spacing: DeferTheme.spacing(2.25)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
                Text(dateText)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(DeferTheme.textMuted)

                Text(quoteText)
                    .font(.system(size: 18, weight: .regular, design: .default))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Writer, \(quoteAuthor)")
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [orbGradient[0], orbGradient[1]],
                        startPoint: quoteOrbDrift ? .topLeading : .bottomLeading,
                        endPoint: quoteOrbDrift ? .bottomTrailing : .topTrailing
                    )
                )
                .opacity(0.88)
                .frame(width: 54, height: 54)
                .onAppear {
                    withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                        quoteOrbDrift.toggle()
                    }
                }
        }
        .padding(.vertical, DeferTheme.spacing(2.25))
    }
}
