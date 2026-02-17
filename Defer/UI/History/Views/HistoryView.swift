import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \CompletionHistory.completedAt, order: .reverse)
    private var completions: [CompletionHistory]

    @StateObject private var viewModel = HistoryViewModel()

    private var averageDuration: Int {
        viewModel.averageDuration(from: completions)
    }

    private var categoryBreakdown: [(DeferCategory, Int)] {
        viewModel.categoryBreakdown(from: completions)
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
                            HistoryEmptyStateView()
                        } else {
                            HistorySummarySectionView(
                                completionCount: completions.count,
                                averageDuration: averageDuration
                            )
                            HistoryBreakdownSectionView(categoryBreakdown: categoryBreakdown)
                            HistoryTimelineSectionView(completions: completions)
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 80)
                }
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewFixtures.inMemoryContainerWithSeedData())
}
