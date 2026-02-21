import SwiftUI

struct DeferRecentUrgesCardView: View {
    let urgeLogs: [UrgeLog]

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            HStack {
                Text("Recent Urges")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer()

                Text("\(urgeLogs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
            }

            if urgeLogs.isEmpty {
                Text("No urge logs yet.")
                    .font(.subheadline)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            } else {
                VStack(spacing: DeferTheme.spacing(0.8)) {
                    ForEach(urgeLogs, id: \.id) { log in
                        urgeRow(log)
                    }
                }
            }
        }
        .padding(DeferTheme.spacing(1.25))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func urgeRow(_ log: UrgeLog) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(color(for: log.intensity).opacity(0.9))
                .frame(width: 9, height: 9)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(log.loggedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)

                    if log.usedFallbackAction {
                        Text("Fallback")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(DeferTheme.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(DeferTheme.success.opacity(0.45)))
                    }
                }

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
        .padding(.vertical, 1)
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

        DeferRecentUrgesCardView(urgeLogs: logs)
            .padding()
    }
}
