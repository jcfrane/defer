import Foundation

struct DecisionAnalyticsPayload: Codable {
    let event: String
    let intentID: UUID
    let category: String
    let protocolType: String
    let protocolDurationHours: Int
    let timestamp: Date
    let extras: [String: String]
}

enum DecisionAnalytics {
    private static let queue = DispatchQueue(label: "com.jcfrane.defer.analytics", qos: .utility)
    private static let defaults = UserDefaults.standard
    private static let storageKey = "analytics.events.buffer"
    private static let maxBufferedEvents = 400

    static func track(
        event: String,
        intent: DeferItem,
        timestamp: Date = .now,
        extras: [String: String] = [:]
    ) {
        let payload = DecisionAnalyticsPayload(
            event: event,
            intentID: intent.id,
            category: intent.category.rawValue,
            protocolType: intent.delayProtocolType.rawValue,
            protocolDurationHours: intent.delayDurationHours,
            timestamp: timestamp,
            extras: extras
        )

        queue.async {
            var existing = loadUnsafe()
            existing.append(payload)
            if existing.count > maxBufferedEvents {
                existing.removeFirst(existing.count - maxBufferedEvents)
            }
            saveUnsafe(existing)
        }
    }

    static func bufferedEvents() -> [DecisionAnalyticsPayload] {
        queue.sync {
            loadUnsafe()
        }
    }

    static func clear() {
        queue.sync {
            saveUnsafe([])
        }
    }

    private static func loadUnsafe() -> [DecisionAnalyticsPayload] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        return (try? JSONDecoder().decode([DecisionAnalyticsPayload].self, from: data)) ?? []
    }

    private static func saveUnsafe(_ payloads: [DecisionAnalyticsPayload]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try? encoder.encode(payloads)
        defaults.set(data, forKey: storageKey)
    }
}

extension DecisionAnalytics {
    static let desireCaptured = "desire_captured"
    static let delayProtocolSelected = "delay_protocol_selected"
    static let urgeLogged = "urge_logged"
    static let checkpointDue = "checkpoint_due"
    static let decisionRecorded = "decision_recorded"
    static let decisionPostponed = "decision_postponed"
    static let reflectionSubmitted = "reflection_submitted"
    static let notificationOpened = "notification_opened"
}
