//
//  DeferApp.swift
//  Defer
//
//  Created by JC Frane on 2/7/26.
//

import SwiftUI
import SwiftData

@main
struct DeferApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer

    init() {
        let container = DeferModelContainer.makeModelContainer()
        modelContainer = container
        BackgroundTaskManager.registerIfNeeded(modelContainer: container)
        BackgroundTaskManager.scheduleAppRefresh()
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
