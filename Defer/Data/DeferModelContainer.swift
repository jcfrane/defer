import Foundation
import SwiftData

enum DeferModelContainer {
    static func makeModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            DeferItem.self,
            StreakRecord.self,
            CompletionHistory.self,
            Achievement.self,
            Quote.self,
            UrgeLog.self,
            RewardLedgerEntry.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

#if DEBUG
    static func logStorePath(fileManager: FileManager = .default) {
        guard let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            print("[Defer][DEBUG] Could not resolve Application Support directory.")
            return
        }

        guard let storePath = resolveStorePath(
            in: applicationSupportURL,
            fileManager: fileManager
        ) else {
            print("[Defer][DEBUG] SwiftData store file not found under: \(applicationSupportURL.path)")
            return
        }

        print("[Defer][DEBUG] SwiftData store path: \(storePath)")
    }

    private static func resolveStorePath(in rootURL: URL, fileManager: FileManager) -> String? {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var candidates: [URL] = []

        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                  values.isRegularFile == true else {
                continue
            }

            let fileExtension = url.pathExtension.lowercased()
            guard fileExtension == "sqlite" || fileExtension == "store" else {
                continue
            }

            candidates.append(url)
        }

        let sortedCandidates = candidates.sorted { lhs, rhs in
            let lhsName = lhs.lastPathComponent.lowercased()
            let rhsName = rhs.lastPathComponent.lowercased()

            if lhsName.contains("default") != rhsName.contains("default") {
                return lhsName.contains("default")
            }

            if lhs.pathExtension.lowercased() != rhs.pathExtension.lowercased() {
                return lhs.pathExtension.lowercased() == "sqlite"
            }

            return lhs.path < rhs.path
        }

        return sortedCandidates.first?.path
    }
#endif
}
