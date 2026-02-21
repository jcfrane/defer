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
}
