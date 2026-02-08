import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "rosette")
                }
        }
        .tint(DeferTheme.tabActive)
        .toolbarBackground(DeferTheme.primary, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

#Preview {
    ContentView()
        .modelContainer(DeferModelContainer.makeModelContainer(inMemory: true))
}
