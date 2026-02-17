import SwiftUI

struct HistoryBreakdownSectionView: View {
    let categoryBreakdown: [HistoryCategoryStat]
    let selectedCategory: DeferCategory?
    let onSelectCategory: (DeferCategory?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            HStack {
                Text("Category Energy")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer()

                Text(selectedCategory?.displayName ?? "All")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.84))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DeferTheme.spacing(0.75)) {
                    historyFilterChip(
                        title: "All",
                        icon: "line.3.horizontal.decrease.circle.fill",
                        isSelected: selectedCategory == nil,
                        action: { onSelectCategory(nil) }
                    )

                    ForEach(categoryBreakdown) { stat in
                        historyFilterChip(
                            title: stat.category.displayName,
                            icon: DeferTheme.categoryIcon(for: stat.category),
                            isSelected: selectedCategory == stat.category,
                            action: {
                                onSelectCategory(selectedCategory == stat.category ? nil : stat.category)
                            }
                        )
                    }
                }
                .padding(.vertical, 1)
            }

            if categoryBreakdown.isEmpty {
                Text("No categories yet")
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                    .font(.subheadline)
            } else {
                VStack(spacing: DeferTheme.spacing(1)) {
                    ForEach(categoryBreakdown) { stat in
                        HistoryCategoryMeterRowView(
                            stat: stat,
                            isSelected: selectedCategory == stat.category,
                            action: {
                                onSelectCategory(selectedCategory == stat.category ? nil : stat.category)
                            }
                        )
                    }
                }
            }
        }
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private func historyFilterChip(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(DeferTheme.textPrimary)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? DeferTheme.warning.opacity(0.62) : Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isSelected ? 0.32 : 0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Filters timeline results")
    }
}

private struct HistoryCategoryMeterRowView: View {
    let stat: HistoryCategoryStat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DeferTheme.spacing(1)) {
                ZStack {
                    Circle()
                        .fill(DeferTheme.surface.opacity(0.9))

                    Image(systemName: DeferTheme.categoryIcon(for: stat.category))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(stat.category.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DeferTheme.textPrimary)

                        Spacer()

                        Text("\(Int(stat.share * 100))%")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    }

                    GeometryReader { proxy in
                        let fullWidth = max(proxy.size.width, 0)
                        let fillWidth = max(10, fullWidth * stat.share)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [DeferTheme.warning.opacity(0.9), DeferTheme.success.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: fillWidth)
                        }
                    }
                    .frame(height: 8)
                }

                Text("\(stat.count)")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(DeferTheme.textPrimary)
                    .frame(minWidth: 32, alignment: .trailing)
            }
            .padding(.horizontal, DeferTheme.spacing(1.1))
            .padding(.vertical, DeferTheme.spacing(1))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.18 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(isSelected ? 0.3 : 0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(stat.category.displayName), \(stat.count) completions")
        .accessibilityHint("Shows timeline entries for this category")
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground.ignoresSafeArea()

        HistoryBreakdownSectionView(
            categoryBreakdown: [
                HistoryCategoryStat(category: .habit, count: 5, share: 0.5),
                HistoryCategoryStat(category: .health, count: 3, share: 0.3),
                HistoryCategoryStat(category: .nutrition, count: 2, share: 0.2)
            ],
            selectedCategory: .habit,
            onSelectCategory: { _ in }
        )
        .padding()
    }
}
