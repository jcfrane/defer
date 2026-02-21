import BackgroundTasks
import Foundation
import SwiftData

enum BackgroundTaskManager {
    static let appRefreshIdentifier = "com.jcfrane.Defer.app-refresh"
    static let refreshInterval: TimeInterval = 6 * 60 * 60

    private static var hasRegistered = false

    static func registerIfNeeded(modelContainer: ModelContainer) {
        guard !hasRegistered else { return }

        let didRegister = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: appRefreshIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            handleAppRefresh(task: refreshTask, modelContainer: modelContainer)
        }

        hasRegistered = didRegister
    }

    static func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: appRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: appRefreshIdentifier)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("Failed to submit app refresh task: \(error)")
            #endif
        }
    }

    private static func handleAppRefresh(task: BGAppRefreshTask, modelContainer: ModelContainer) {
        scheduleAppRefresh()

        let refreshWork = Task { @MainActor in
            if Task.isCancelled { return false }

            let context = ModelContext(modelContainer)
            let repository = SwiftDataDeferRepository(context: context)

            do {
                _ = try repository.refreshLifecycle(asOf: .now)
                return true
            } catch {
                return false
            }
        }

        task.expirationHandler = {
            refreshWork.cancel()
        }

        Task {
            let success = await refreshWork.value
            task.setTaskCompleted(success: success)
        }
    }
}
