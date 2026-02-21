import Foundation

enum DataExportFormat: String, CaseIterable, Identifiable {
    case json
    case csv

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .json:
            return "json"
        case .csv:
            return "csv"
        }
    }
}

enum DataExportServiceError: LocalizedError {
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .writeFailed:
            return "Unable to write export file."
        }
    }
}

struct DataExportService {
    fileprivate static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func export(
        format: DataExportFormat,
        defers: [DeferItem],
        completions: [CompletionHistory],
        achievements: [Achievement],
        now: Date = .now
    ) throws -> URL {
        let fileName = "defer-backup-\(Int(now.timeIntervalSince1970)).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        let data: Data
        switch format {
        case .json:
            data = try makeJSONData(
                defers: defers,
                completions: completions,
                achievements: achievements,
                generatedAt: now
            )
        case .csv:
            data = makeCSVData(
                defers: defers,
                completions: completions,
                achievements: achievements,
                generatedAt: now
            )
        }

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            throw DataExportServiceError.writeFailed
        }
    }

    private func makeJSONData(
        defers: [DeferItem],
        completions: [CompletionHistory],
        achievements: [Achievement],
        generatedAt: Date
    ) throws -> Data {
        let payload = JSONPayload(
            generatedAt: Self.isoFormatter.string(from: generatedAt),
            activeAndHistoricalDefers: defers
                .sorted { $0.createdAt < $1.createdAt }
                .map(JSONDeferRow.init(item:)),
            completionHistory: completions
                .sorted { $0.completedAt > $1.completedAt }
                .map(JSONCompletionRow.init(item:)),
            achievements: achievements
                .sorted { $0.unlockedAt > $1.unlockedAt }
                .map(JSONAchievementRow.init(item:))
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    private func makeCSVData(
        defers: [DeferItem],
        completions: [CompletionHistory],
        achievements: [Achievement],
        generatedAt: Date
    ) -> Data {
        var lines: [String] = []
        lines.append("Defer Backup Generated At,\(escapeCSV(Self.isoFormatter.string(from: generatedAt)))")
        lines.append("")

        lines.append("[Defers]")
        lines.append("id,title,details,category,type,status,startDate,targetDate,strictMode,streakCount,lastCheckInDate,currentMilestone,createdAt,updatedAt")
        for item in defers.sorted(by: { $0.createdAt < $1.createdAt }) {
            lines.append([
                item.id.uuidString,
                item.title,
                item.details ?? "",
                item.category.rawValue,
                item.type.rawValue,
                item.status.rawValue,
                Self.isoFormatter.string(from: item.startDate),
                Self.isoFormatter.string(from: item.targetDate),
                item.strictMode ? "true" : "false",
                "\(item.streakCount)",
                item.lastCheckInDate.map(Self.isoFormatter.string(from:)) ?? "",
                "\(item.currentMilestone)",
                Self.isoFormatter.string(from: item.createdAt),
                Self.isoFormatter.string(from: item.updatedAt)
            ]
            .map(escapeCSV)
            .joined(separator: ","))
        }

        lines.append("")
        lines.append("[CompletionHistory]")
        lines.append("id,deferID,deferTitle,category,type,startDate,targetDate,completedAt,durationDays,summary,createdAt")
        for item in completions.sorted(by: { $0.completedAt > $1.completedAt }) {
            lines.append([
                item.id.uuidString,
                item.deferID.uuidString,
                item.deferTitle,
                item.category.rawValue,
                item.type.rawValue,
                Self.isoFormatter.string(from: item.startDate),
                Self.isoFormatter.string(from: item.targetDate),
                Self.isoFormatter.string(from: item.completedAt),
                "\(item.durationDays)",
                item.summary ?? "",
                Self.isoFormatter.string(from: item.createdAt)
            ]
            .map(escapeCSV)
            .joined(separator: ","))
        }

        lines.append("")
        lines.append("[Achievements]")
        lines.append("id,key,title,details,tier,unlockedAt,sourceDeferID,createdAt")
        for item in achievements.sorted(by: { $0.unlockedAt > $1.unlockedAt }) {
            lines.append([
                item.id.uuidString,
                item.key,
                item.title,
                item.details,
                item.tier.rawValue,
                Self.isoFormatter.string(from: item.unlockedAt),
                item.sourceDeferID?.uuidString ?? "",
                Self.isoFormatter.string(from: item.createdAt)
            ]
            .map(escapeCSV)
            .joined(separator: ","))
        }

        return Data(lines.joined(separator: "\n").utf8)
    }

    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

private struct JSONPayload: Codable {
    let generatedAt: String
    let activeAndHistoricalDefers: [JSONDeferRow]
    let completionHistory: [JSONCompletionRow]
    let achievements: [JSONAchievementRow]
}

private struct JSONDeferRow: Codable {
    let id: String
    let title: String
    let details: String?
    let category: String
    let type: String
    let status: String
    let startDate: String
    let targetDate: String
    let strictMode: Bool
    let streakCount: Int
    let lastCheckInDate: String?
    let currentMilestone: Int
    let createdAt: String
    let updatedAt: String

    init(item: DeferItem) {
        id = item.id.uuidString
        title = item.title
        details = item.details
        category = item.category.rawValue
        type = item.type.rawValue
        status = item.status.rawValue
        startDate = DataExportService.isoFormatter.string(from: item.startDate)
        targetDate = DataExportService.isoFormatter.string(from: item.targetDate)
        strictMode = item.strictMode
        streakCount = item.streakCount
        lastCheckInDate = item.lastCheckInDate.map(DataExportService.isoFormatter.string(from:))
        currentMilestone = item.currentMilestone
        createdAt = DataExportService.isoFormatter.string(from: item.createdAt)
        updatedAt = DataExportService.isoFormatter.string(from: item.updatedAt)
    }
}

private struct JSONCompletionRow: Codable {
    let id: String
    let deferID: String
    let deferTitle: String
    let category: String
    let type: String
    let startDate: String
    let targetDate: String
    let completedAt: String
    let durationDays: Int
    let summary: String?
    let createdAt: String

    init(item: CompletionHistory) {
        id = item.id.uuidString
        deferID = item.deferID.uuidString
        deferTitle = item.deferTitle
        category = item.category.rawValue
        type = item.type.rawValue
        startDate = DataExportService.isoFormatter.string(from: item.startDate)
        targetDate = DataExportService.isoFormatter.string(from: item.targetDate)
        completedAt = DataExportService.isoFormatter.string(from: item.completedAt)
        durationDays = item.durationDays
        summary = item.summary
        createdAt = DataExportService.isoFormatter.string(from: item.createdAt)
    }
}

private struct JSONAchievementRow: Codable {
    let id: String
    let key: String
    let title: String
    let details: String
    let tier: String
    let unlockedAt: String
    let sourceDeferID: String?
    let createdAt: String

    init(item: Achievement) {
        id = item.id.uuidString
        key = item.key
        title = item.title
        details = item.details
        tier = item.tier.rawValue
        unlockedAt = DataExportService.isoFormatter.string(from: item.unlockedAt)
        sourceDeferID = item.sourceDeferID?.uuidString
        createdAt = DataExportService.isoFormatter.string(from: item.createdAt)
    }
}
