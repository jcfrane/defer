import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \CompletionHistory.completedAt, order: .reverse)
    private var decisions: [CompletionHistory]

    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedCategory: DeferCategory?

    private var summary: HistorySummaryMetrics {
        viewModel.summaryMetrics(from: decisions)
    }

    private var categoryBreakdown: [HistoryCategoryStat] {
        viewModel.categoryBreakdown(from: decisions)
    }

    private var monthlyRhythm: [HistoryMonthStat] {
        viewModel.monthlyRhythm(from: decisions)
    }

    private var filteredDecisions: [CompletionHistory] {
        viewModel.filteredDecisions(from: decisions, category: selectedCategory)
    }

    private var timelineGroups: [HistoryTimelineGroup] {
        viewModel.timelineGroups(from: filteredDecisions)
    }

    private var subtitle: String {
        viewModel.historySubtitle(for: summary)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                HistoryBackgroundAtmosphereView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeferTheme.spacing(2)) {
                        AppPageHeaderView(
                            title: "History",
                            subtitle: {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                            },
                            trailing: {
                                Label("\(summary.decisionCount)", systemImage: "sparkles")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DeferTheme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(DeferTheme.surface.opacity(0.72)))
                            }
                        )

                        if decisions.isEmpty {
                            HistoryEmptyStateView()
                        } else {
                            HistorySummarySectionView(
                                summary: summary,
                                monthlyRhythm: monthlyRhythm
                            )

                            HistoryBreakdownSectionView(
                                categoryBreakdown: categoryBreakdown,
                                selectedCategory: selectedCategory,
                                onSelectCategory: { selectedCategory = $0 }
                            )

                            HistoryTimelineSectionView(
                                timelineGroups: timelineGroups,
                                selectedCategory: selectedCategory,
                                onClearFilter: { selectedCategory = nil }
                            )
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 100)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.84), value: selectedCategory)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewFixtures.inMemoryContainerWithSeedData())
}
