import SwiftUI

struct HistorySummarySectionView: View {
    let completionCount: Int
    let averageDuration: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Completion Stats")
                .font(.title3.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)

            HStack(spacing: 12) {
                HistoryStatBlockView(title: "Completed", value: "\(completionCount)", icon: "checkmark.circle.fill")
                HistoryStatBlockView(title: "Avg Length", value: "\(averageDuration)d", icon: "calendar")
            }
        }
        .padding(18)
        .glassCard()
    }
}

private struct HistoryStatBlockView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(DeferTheme.textMuted)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(DeferTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DeferTheme.surface.opacity(0.65)))
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        HistorySummarySectionView(completionCount: 7, averageDuration: 14)
            .padding()
    }
}
