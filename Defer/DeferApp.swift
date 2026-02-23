//
//  DeferApp.swift
//  Defer
//
//  Created by JC Frane on 2/7/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct DeferApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer

    init() {
        Self.configureNavigationBarAppearance()

        let container = DeferModelContainer.makeModelContainer()
        modelContainer = container
#if DEBUG
        DeferModelContainer.logStorePath()
#endif
        BackgroundTaskManager.registerIfNeeded(modelContainer: container)
        BackgroundTaskManager.scheduleAppRefresh()
    }

    private static func configureNavigationBarAppearance() {
        let textColor = UIColor(DeferTheme.textPrimary)
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = .clear
        navAppearance.titleTextAttributes = [.foregroundColor: textColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: textColor]

        let navigationBar = UINavigationBar.appearance()
        navigationBar.tintColor = textColor
        navigationBar.standardAppearance = navAppearance
        navigationBar.scrollEdgeAppearance = navAppearance
        navigationBar.compactAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active || newPhase == .background {
                BackgroundTaskManager.scheduleAppRefresh()
            }
        }
    }
}
