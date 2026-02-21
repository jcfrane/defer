import Foundation

struct DeferTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let whyItMatters: String
    let protocolType: DelayProtocolType
    let durationHours: Int
    let fallbackAction: String
    let suggestedCost: Double?

    func delayProtocol(from startDate: Date, calendar: Calendar = .current) -> DelayProtocol {
        if protocolType == .customDate {
            let customDate = calendar.date(byAdding: .hour, value: durationHours, to: startDate)
            return DelayProtocol(type: .customDate, customDate: customDate)
        }

        return DelayProtocol(type: protocolType)
    }
}

enum DeferTemplateCatalog {
    static func templates(for category: DeferCategory) -> [DeferTemplate] {
        switch category {
        case .health:
            return [
                DeferTemplate(
                    id: "health-late-snack",
                    title: "Late-night snack urge",
                    whyItMatters: "I sleep and recover better when I pause this urge.",
                    protocolType: .tenMinutes,
                    durationHours: 1,
                    fallbackAction: "Drink water and take a short walk.",
                    suggestedCost: nil
                ),
                DeferTemplate(
                    id: "health-rest-day",
                    title: "Skip workout today",
                    whyItMatters: "I want consistency over convenience.",
                    protocolType: .twentyFourHours,
                    durationHours: 24,
                    fallbackAction: "Do 5 minutes of stretching instead.",
                    suggestedCost: nil
                )
            ]
        case .spending:
            return [
                DeferTemplate(
                    id: "spending-24h-purchase",
                    title: "Impulse purchase",
                    whyItMatters: "I want purchases to match my priorities, not moods.",
                    protocolType: .twentyFourHours,
                    durationHours: 24,
                    fallbackAction: "Add item to wishlist and review tomorrow.",
                    suggestedCost: 40
                ),
                DeferTemplate(
                    id: "spending-payday",
                    title: "Non-essential purchase",
                    whyItMatters: "I only buy this if I still want it on payday.",
                    protocolType: .untilPayday,
                    durationHours: 24 * 14,
                    fallbackAction: "Compare alternatives before deciding.",
                    suggestedCost: 120
                )
            ]
        case .nutrition:
            return [
                DeferTemplate(
                    id: "nutrition-dessert",
                    title: "Dessert craving",
                    whyItMatters: "I feel better when I avoid reactive sugar choices.",
                    protocolType: .tenMinutes,
                    durationHours: 1,
                    fallbackAction: "Eat fruit or tea first.",
                    suggestedCost: nil
                ),
                DeferTemplate(
                    id: "nutrition-order-out",
                    title: "Order takeout urge",
                    whyItMatters: "I want food decisions to support energy tomorrow.",
                    protocolType: .twentyFourHours,
                    durationHours: 24,
                    fallbackAction: "Cook one simple backup meal.",
                    suggestedCost: 25
                )
            ]
        case .habit:
            return [
                DeferTemplate(
                    id: "habit-social-scroll",
                    title: "Open social apps",
                    whyItMatters: "I protect focused time before entertainment.",
                    protocolType: .tenMinutes,
                    durationHours: 1,
                    fallbackAction: "Read one saved article instead.",
                    suggestedCost: nil
                ),
                DeferTemplate(
                    id: "habit-binge",
                    title: "Start another episode",
                    whyItMatters: "I want better sleep and next-day clarity.",
                    protocolType: .seventyTwoHours,
                    durationHours: 72,
                    fallbackAction: "Set a 5-minute wind-down timer.",
                    suggestedCost: nil
                )
            ]
        case .relationship:
            return [
                DeferTemplate(
                    id: "relationship-reactive-message",
                    title: "Send reactive message",
                    whyItMatters: "I communicate better when I respond, not react.",
                    protocolType: .tenMinutes,
                    durationHours: 1,
                    fallbackAction: "Draft the message and revisit after breathing.",
                    suggestedCost: nil
                ),
                DeferTemplate(
                    id: "relationship-big-decision",
                    title: "Make emotional decision",
                    whyItMatters: "I want to make this choice from clarity.",
                    protocolType: .twentyFourHours,
                    durationHours: 24,
                    fallbackAction: "Talk it through with a trusted person.",
                    suggestedCost: nil
                )
            ]
        case .productivity:
            return [
                DeferTemplate(
                    id: "productivity-context-switch",
                    title: "Switch tasks impulsively",
                    whyItMatters: "I finish more when I delay distractions.",
                    protocolType: .tenMinutes,
                    durationHours: 1,
                    fallbackAction: "Write next step for current task first.",
                    suggestedCost: nil
                ),
                DeferTemplate(
                    id: "productivity-new-tool",
                    title: "Buy a new productivity tool",
                    whyItMatters: "I choose tools intentionally, not from FOMO.",
                    protocolType: .seventyTwoHours,
                    durationHours: 72,
                    fallbackAction: "Audit current workflow gaps first.",
                    suggestedCost: 60
                )
            ]
        case .custom:
            return [
                DeferTemplate(
                    id: "custom-short-delay",
                    title: "Short pause intent",
                    whyItMatters: "I want one structured pause before deciding.",
                    protocolType: .twentyFourHours,
                    durationHours: 24,
                    fallbackAction: "Capture the urge and revisit at checkpoint.",
                    suggestedCost: nil
                ),
                DeferTemplate(
                    id: "custom-long-delay",
                    title: "Longer decision horizon",
                    whyItMatters: "I need distance to choose what matters most.",
                    protocolType: .customDate,
                    durationHours: 24 * 7,
                    fallbackAction: "Set one reminder and do nothing else for now.",
                    suggestedCost: nil
                )
            ]
        }
    }
}
