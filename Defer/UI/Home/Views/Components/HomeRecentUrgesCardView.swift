import SwiftUI

struct HomeRecentUrgesCardView: View {
    let urgeLogs: [UrgeLog]

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            HStack {
                Text("Recent Urges")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer()

                Text("7 days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
            }

            if urgeLogs.isEmpty {
                Text("No urge logs yet")
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            } else {
                VStack(spacing: DeferTheme.spacing(0.8)) {
                    ForEach(urgeLogs, id: \.id) { log in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(color(for: log.intensity).opacity(0.88))
                                .frame(width: 10, height: 10)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.deferItem?.title ?? "Intent")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DeferTheme.textPrimary)

                                Text(log.loggedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.74))

                                if let note = log.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                                        .lineLimit(2)
                                }
                            }

                            Spacer(minLength: 0)

                            Text("\(log.intensity)/5")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private func color(for intensity: Int) -> Color {
        switch intensity {
        case 1...2:
            return DeferTheme.success
        case 3:
            return DeferTheme.warning
        default:
            return DeferTheme.danger
        }
    }
}

#Preview {
    let item = PreviewFixtures.sampleDefer(
        title: "Impulse order",
        details: "Hold until tomorrow.",
        category: .spending,
        status: .activeWait,
        strictMode: false,
        streakCount: 0,
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    )

    let logs = [
        UrgeLog(deferID: item.id, loggedAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now, intensity: 4, note: "Saw an ad", usedFallbackAction: true, deferItem: item),
        UrgeLog(deferID: item.id, loggedAt: Calendar.current.date(byAdding: .hour, value: -8, to: .now) ?? .now, intensity: 3, note: "Browsing", usedFallbackAction: false, deferItem: item)
    ]

    return ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HomeRecentUrgesCardView(urgeLogs: logs)
            .padding()
    }
}
