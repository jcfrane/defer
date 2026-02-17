import Foundation

enum HomeFormatting {
    private static let quoteDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static func quoteDateLabel(from date: Date) -> String {
        quoteDateFormatter.string(from: date)
    }

    static func ordinalSuffix(for day: Int) -> String {
        let teens = day % 100
        if teens >= 11 && teens <= 13 {
            return "th"
        }

        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    static func timeOfDayTitle(from date: Date = .now, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)

        if hour == 12 {
            return "Noon"
        } else if hour >= 5 && hour < 12 {
            return "Morning"
        } else if hour > 12 && hour < 18 {
            return "Afternoon"
        } else {
            return "Evening"
        }
    }

    static func weekdayLetters(calendar: Calendar = .current) -> [String] {
        calendar.veryShortStandaloneWeekdaySymbols
    }

    static func currentWeekdayIndex(from date: Date = .now, calendar: Calendar = .current) -> Int {
        max(0, min(6, calendar.component(.weekday, from: date) - 1))
    }
}
