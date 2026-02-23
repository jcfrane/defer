import Foundation

struct DailyQuote {
    let text: String
    let author: String?
}

final class MotivationService {
    private let localQuotes: [DailyQuote] = [
        DailyQuote(text: "You have power over your mind - not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius"),
        DailyQuote(text: "The impediment to action advances action. What stands in the way becomes the way.", author: "Marcus Aurelius"),
        DailyQuote(text: "Our life is what our thoughts make it.", author: "Marcus Aurelius"),
        DailyQuote(text: "We suffer more often in imagination than in reality.", author: "Seneca"),
        DailyQuote(text: "He who is brave is free.", author: "Seneca"),
        DailyQuote(text: "No man is free who is not master of himself.", author: "Epictetus"),
        DailyQuote(text: "First say to yourself what you would be; and then do what you have to do.", author: "Epictetus"),
        DailyQuote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
        DailyQuote(text: "The man who moves a mountain begins by carrying away small stones.", author: "Confucius"),
        DailyQuote(text: "A journey of a thousand miles begins with a single step.", author: "Lao Tzu"),
        DailyQuote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
        DailyQuote(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
        DailyQuote(text: "Knowing is not enough; we must apply. Willing is not enough; we must do.", author: "Johann Wolfgang von Goethe"),
        DailyQuote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        DailyQuote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
        DailyQuote(text: "Nothing will work unless you do.", author: "Maya Angelou"),
        DailyQuote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
        DailyQuote(text: "It always seems impossible until it's done.", author: "Nelson Mandela"),
        DailyQuote(text: "The best way out is always through.", author: "Robert Frost"),
        DailyQuote(text: "Success is the sum of small efforts, repeated day in and day out.", author: "Robert Collier")
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
