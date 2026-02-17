import SwiftUI

struct HistoryTimelineSectionView: View {
    let completions: [CompletionHistory]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Timeline")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)

            ForEach(completions) { completion in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(completion.deferTitle)
                            .font(.headline)
                            .foregroundStyle(DeferTheme.textPrimary)
                        Spacer()
                        Text(completion.completedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted)
                    }

                    HStack(spacing: 12) {
                        Text(completion.category.displayName)
                        Text("\(completion.durationDays) days")
                    }
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted)

                    if let summary = completion.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(DeferTheme.surface.opacity(0.65)))
            }
        }
        .padding(18)
        .glassCard()
    }
}

#Preview {
    let item = PreviewFixtures.sampleDefer(
        title: "No Social Media",
        details: "No scrolling after 9PM",
        category: .habit,
        status: .completed,
        strictMode: false,
        streakCount: 11,
        startDate: Calendar.current.date(byAdding: .day, value: -20, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
    )

    let completion = PreviewFixtures.sampleCompletion(
        item: item,
        completedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    )

    return ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        HistoryTimelineSectionView(completions: [completion])
            .padding()
    }
}
