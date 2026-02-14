import SwiftUI

struct HomeControlsRowView: View {
    @Binding var sortOption: HomeSortOption
    @Binding var selectedCategory: DeferCategory?

    var body: some View {
        HStack(spacing: DeferTheme.spacing(1.25)) {
            Menu {
                ForEach(HomeSortOption.allCases) { option in
                    Button(option.rawValue) { sortOption = option }
                }
            } label: {
                Label(sortOption.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(DeferTheme.surface.opacity(0.76)))
                    .foregroundStyle(DeferTheme.textPrimary)
            }

            Menu {
                Button("All Categories") { selectedCategory = nil }
                ForEach(DeferCategory.allCases) { category in
                    Button(category.displayName) { selectedCategory = category }
                }
            } label: {
                Label(selectedCategory?.displayName ?? "All Categories", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(DeferTheme.surface.opacity(0.76)))
                    .foregroundStyle(DeferTheme.textPrimary)
            }

            Spacer()
        }
    }
}
