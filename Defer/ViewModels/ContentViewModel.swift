import SwiftUI
import Combine
import UIKit

@MainActor
final class ContentViewModel: ObservableObject {
    init() {
        configureTabBarAppearance()
    }

    private func configureTabBarAppearance() {
        let selectedColor = UIColor.white
        let unselectedColor = UIColor.white
        let backgroundColor = UIColor(red: 0.15, green: 0.32, blue: 0.25, alpha: 1.0)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.2)

        let stacked = appearance.stackedLayoutAppearance
        stacked.selected.iconColor = selectedColor
        stacked.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        stacked.normal.iconColor = unselectedColor
        stacked.normal.titleTextAttributes = [.foregroundColor: unselectedColor]

        appearance.inlineLayoutAppearance = stacked
        appearance.compactInlineLayoutAppearance = stacked

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
