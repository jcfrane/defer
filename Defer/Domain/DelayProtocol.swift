import Foundation

struct DelayProtocol: Equatable {
    let type: DelayProtocolType
    let customDate: Date?

    init(type: DelayProtocolType, customDate: Date? = nil) {
        self.type = type
        self.customDate = customDate
    }

    var durationHours: Int {
        switch type {
        case .tenMinutes:
            return 1
        case .twentyFourHours:
            return 24
        case .seventyTwoHours:
            return 72
        case .untilPayday:
            return 24 * 14
        case .customDate:
            guard let customDate else { return 24 }
            return max(1, Int(customDate.timeIntervalSince(.now) / 3600.0))
        }
    }

    func decisionDate(from startDate: Date, calendar: Calendar = .current) -> Date {
        switch type {
        case .tenMinutes:
            return startDate.addingTimeInterval(10 * 60)
        case .twentyFourHours:
            return startDate.addingTimeInterval(24 * 60 * 60)
        case .seventyTwoHours:
            return startDate.addingTimeInterval(72 * 60 * 60)
        case .untilPayday:
            return Self.nextPayday(after: startDate, calendar: calendar)
        case .customDate:
            return max(customDate ?? startDate.addingTimeInterval(24 * 60 * 60), startDate.addingTimeInterval(10 * 60))
        }
    }

    private static func nextPayday(after date: Date, calendar: Calendar) -> Date {
        let day = calendar.component(.day, from: date)

        func with(day: Int, monthOffset: Int = 0) -> Date? {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: date) else {
                return nil
            }

            var components = calendar.dateComponents([.year, .month], from: monthDate)
            components.day = day
            components.hour = 9
            components.minute = 0
            components.second = 0
            return calendar.date(from: components)
        }

        if day < 15, let thisMonthPayday = with(day: 15), thisMonthPayday > date {
            return thisMonthPayday
        }

        if let firstOfNextMonth = with(day: 1, monthOffset: 1), firstOfNextMonth > date {
            return firstOfNextMonth
        }

        return date.addingTimeInterval(24 * 60 * 60)
    }
}
