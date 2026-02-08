import Foundation

struct DailyQuote {
    let text: String
    let author: String?
}

final class MotivationService {
    private let localQuotes: [DailyQuote] = [
        DailyQuote(text: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.", author: "Will Durant"),
        DailyQuote(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln"),
        DailyQuote(text: "The first and best victory is to conquer self.", author: "Plato"),
        DailyQuote(text: "He who has a why to live can bear almost any how.", author: "Friedrich Nietzsche"),
        DailyQuote(text: "It is not enough to have a good mind; the main thing is to use it well.", author: "Rene Descartes"),
        DailyQuote(text: "Do not spoil what you have by desiring what you have not.", author: "Epicurus"),
        DailyQuote(text: "Success is the sum of small efforts, repeated day in and day out.", author: "Robert Collier"),
        DailyQuote(text: "The secret of your future is hidden in your daily routine.", author: "Mike Murdock"),
        DailyQuote(text: "First say to yourself what you would be; and then do what you have to do.", author: "Epictetus"),
        DailyQuote(text: "No man is free who is not master of himself.", author: "Epictetus"),
        DailyQuote(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
        DailyQuote(text: "Character is the ability to carry out a good resolution long after the excitement has passed.", author: "Cavett Robert"),
        DailyQuote(text: "The successful warrior is the average man, with laser-like focus.", author: "Bruce Lee"),
        DailyQuote(text: "The price of excellence is discipline.", author: "William Arthur Ward"),
        DailyQuote(text: "A man who suffers before it is necessary suffers more than is necessary.", author: "Seneca"),
        DailyQuote(text: "He who conquers himself is the mightiest warrior.", author: "Confucius"),
        DailyQuote(text: "I never found the companion that was so companionable as solitude.", author: "Henry David Thoreau"),
        DailyQuote(text: "The best way out is always through.", author: "Robert Frost"),
        DailyQuote(text: "We must all suffer one of two things: the pain of discipline or the pain of regret.", author: "Jim Rohn"),
        DailyQuote(text: "Knowing is not enough; we must apply. Willing is not enough; we must do.", author: "Johann Wolfgang von Goethe")
    ]
    
    func quoteOfDay(on date: Date = .now, calendar: Calendar = .current) -> DailyQuote {
        guard !localQuotes.isEmpty else {
            return DailyQuote(text: "One good decision today is enough.", author: nil)
        }
        
        let dayNumber = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayNumber - 1) % localQuotes.count
        return localQuotes[index]
    }
    
    func encouragementMessage(for activeDefers: [DeferItem], today: Date = .now) -> String {
        guard !activeDefers.isEmpty else {
            return "Start one defer today and build momentum from day one."
        }
        
        let checkedInToday = activeDefers.filter { $0.hasCheckedIn(on: today) }.count
        let maxStreak = activeDefers.map(\.streakCount).max() ?? 0
        
        if checkedInToday == activeDefers.count {
            return "All active defers checked in today. Keep the standard high."
        }
        
        if maxStreak >= 100 {
            return "100+ day behavior is identity-level consistency. Protect the streak."
        }
        
        if maxStreak >= 30 {
            return "30-day consistency means your system is working. Stay precise."
        }
        
        if maxStreak >= 7 {
            return "One week of consistency complete. Repeat the same process today."
        }
        
        return "Focus on one clean day. Repeat tomorrow."
    }
}
