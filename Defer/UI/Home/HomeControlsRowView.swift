import SwiftUI

struct HomeControlsRowView: View {
    @Binding var sortOption: HomeSortOption
    @Binding var selectedCategory: DeferCategory?

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(HomeSortOption.allCases) { option in
                    Button(option.rawValue) { sortOption = option }
                }
            } label: {
                Label(sortOption.rawValue, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                    .foregroundStyle(.white)
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
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }
}
