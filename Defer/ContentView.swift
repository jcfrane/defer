import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

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
}

#Preview {
    ContentView()
        .modelContainer(DeferModelContainer.makeModelContainer(inMemory: true))
}
