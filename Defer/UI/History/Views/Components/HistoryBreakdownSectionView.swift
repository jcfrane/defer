import SwiftUI

struct HistoryBreakdownSectionView: View {
    let categoryBreakdown: [(DeferCategory, Int)]

    var body: some View {
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
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()
        HistoryBreakdownSectionView(categoryBreakdown: [(.habit, 4), (.health, 2), (.nutrition, 1)])
            .padding()
    }
}
