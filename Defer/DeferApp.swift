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
    private let modelContainer = DeferModelContainer.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
