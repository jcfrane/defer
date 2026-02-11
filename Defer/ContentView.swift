import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    init() {
        Self.configureTabBarAppearance()
    }

    var body: some View {
        tabShell
    }

    private var tabShell: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
    

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "rosette")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.white)
        .toolbarBackground(DeferTheme.primary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }

    private static func configureTabBarAppearance() {
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

#Preview {
    ContentView()
        .modelContainer(DeferModelContainer.makeModelContainer(inMemory: true))
}
