import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \CompletionHistory.completedAt, order: .reverse)
    private var completions: [CompletionHistory]

    private var averageDuration: Int {
        guard !completions.isEmpty else { return 0 }
        let total = completions.reduce(0) { $0 + $1.durationDays }
        return total / completions.count
    }

    private var categoryBreakdown: [(DeferCategory, Int)] {
        let grouped = Dictionary(grouping: completions, by: \.category)
        return grouped
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DeferTheme.spacing(2)) {
                        AppPageHeaderView(title: "History")

                        if completions.isEmpty {
                            emptyState
                        } else {
                            summarySection
                            breakdownSection
                            timelineSection
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 80)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 44))
                .foregroundStyle(DeferTheme.textPrimary)
            Text("No completions yet")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)
            Text("Your completed defers will appear here with timeline stats.")
                .font(.subheadline)
                .foregroundStyle(DeferTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .glassCard()
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Completion Stats")
                .font(.title3.weight(.bold))
                .foregroundStyle(DeferTheme.textPrimary)

            HStack(spacing: 12) {
                statBlock(title: "Completed", value: "\(completions.count)", icon: "checkmark.circle.fill")
                statBlock(title: "Avg Length", value: "\(averageDuration)d", icon: "calendar")
            }
        }
        .padding(18)
        .glassCard()
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category Breakdown")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)

            if categoryBreakdown.isEmpty {
                Text("No categories yet")
                    .foregroundStyle(DeferTheme.textMuted)
                    .font(.subheadline)
            } else {
                ForEach(categoryBreakdown, id: \.0) { category, count in
                    HStack {
                        Label(category.displayName, systemImage: DeferTheme.categoryIcon(for: category))
                            .foregroundStyle(DeferTheme.textPrimary)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(DeferTheme.textPrimary)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DeferTheme.surface.opacity(0.65)))
                }
            }
        }
        .padding(18)
        .glassCard()
    }

    private var timelineSection: some View {
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

    private func statBlock(title: String, value: String, icon: String) -> some View {
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
