import Foundation

struct DailyQuote {
    let text: String
    let author: String?
}

final class MotivationService {
    private let localQuotes: [DailyQuote] = [
        DailyQuote(text: "Delay buys clarity.", author: "Defer"),
        DailyQuote(text: "Pause. Then choose.", author: "Defer"),
        DailyQuote(text: "Want now is rarely want most.", author: "Defer"),
        DailyQuote(text: "Ten minutes now can save ten days later.", author: "Defer"),
        DailyQuote(text: "Build good choices.", author: "Defer"),
        DailyQuote(text: "Postpone to avoid impulse.", author: "Defer"),
        DailyQuote(text: "A checkpoint is a choice moment.", author: "Defer"),
        DailyQuote(text: "Train consistency, not perfection.", author: "Defer"),
        DailyQuote(text: "Reflect once. Choose better next time.", author: "Defer"),
        DailyQuote(text: "Intentional choices compound.", author: "Defer")
    ]

    func quoteOfDay(on date: Date = .now, calendar: Calendar = .current) -> DailyQuote {
        guard !localQuotes.isEmpty else {
            return DailyQuote(text: "One pause today is enough.", author: nil)
        }

        let dayNumber = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayNumber - 1) % localQuotes.count
        return localQuotes[index]
    }

    func encouragementMessage(for activeDefers: [DeferItem], today: Date = .now) -> String {
        guard !activeDefers.isEmpty else {
            return "Log one desire and set a checkpoint."
        }

        let dueNow = activeDefers.filter { $0.isCheckpointDue(referenceDate: today) }.count
        let withFallback = activeDefers.filter { !($0.fallbackAction?.isEmpty ?? true) }.count
        let withReason = activeDefers.filter { !($0.whyItMatters?.isEmpty ?? true) }.count

        if dueNow > 0 {
            return "\(dueNow) checkpoint\(dueNow == 1 ? "" : "s") due. Decide with intent."
        }

        if withFallback == activeDefers.count {
            return "Fallbacks set. Keep going."
        }

        if withReason == activeDefers.count {
            return "Reasons set. Hold the wait."
        }

        return "Add one reason or fallback."
    }
}
