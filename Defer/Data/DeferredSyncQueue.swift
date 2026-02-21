import Foundation

struct DeferredSyncOperation: Codable, Identifiable {
    enum Kind: String, Codable {
        case deferCreated
        case deferUpdated
        case deferDeleted
        case deferStatusChanged
        case checkInRecorded
        case completionSnapshotCreated
        case achievementUnlocked
    }

    let id: UUID
    let kind: Kind
    let deferID: UUID?
    let createdAt: Date
    let payload: [String: String]

    init(
        id: UUID = UUID(),
        kind: Kind,
        deferID: UUID?,
        createdAt: Date = .now,
        payload: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.deferID = deferID
        self.createdAt = createdAt
        self.payload = payload
    }
}

enum DeferredSyncQueue {
    private static let defaults = UserDefaults.standard
    private static let queue = DispatchQueue(label: "com.jcfrane.defer.sync-queue")
    private static let storageKey = "sync.pending.operations"
    private static let maxQueueSize = 500

    static func enqueue(_ operation: DeferredSyncOperation) {
        queue.sync {
            var operations = loadUnsafe()
            operations.append(operation)
            if operations.count > maxQueueSize {
                operations.removeFirst(operations.count - maxQueueSize)
            }
            saveUnsafe(operations)
        }
    }

    static func pendingOperations() -> [DeferredSyncOperation] {
        queue.sync {
            loadUnsafe()
        }
    }

    static func clear() {
        queue.sync {
            saveUnsafe([])
        }
    }

    private static func loadUnsafe() -> [DeferredSyncOperation] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        return (try? JSONDecoder().decode([DeferredSyncOperation].self, from: data)) ?? []
    }

    private static func saveUnsafe(_ operations: [DeferredSyncOperation]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try? encoder.encode(operations)
        defaults.set(data, forKey: storageKey)
    }
}
