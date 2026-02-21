import Foundation
import Combine

@MainActor
final class DeferFormViewModel: ObservableObject {
    @Published var title: String
    @Published var whyItMatters: String
    @Published var category: DeferCategory
    @Published var startDate: Date
    @Published var protocolType: DelayProtocolType
    @Published var customDecisionDate: Date
    @Published var estimatedCostText: String
    @Published var fallbackAction: String
    @Published private(set) var selectedTemplateID: String?

    init(initialDraft: DeferDraft) {
        self.title = initialDraft.title
        self.whyItMatters = initialDraft.whyItMatters
        self.category = initialDraft.category
        self.startDate = initialDraft.startDate
        self.protocolType = initialDraft.delayProtocol.type
        self.customDecisionDate = initialDraft.delayProtocol.customDate ?? initialDraft.startDate.addingTimeInterval(24 * 60 * 60)
        if let estimatedCost = initialDraft.estimatedCost {
            self.estimatedCostText = String(format: "%.2f", estimatedCost)
        } else {
            self.estimatedCostText = ""
        }
        self.fallbackAction = initialDraft.fallbackAction
        self.selectedTemplateID = nil
    }

    var availableTemplates: [DeferTemplate] {
        DeferTemplateCatalog.templates(for: category)
    }

    var selectedTemplate: DeferTemplate? {
        availableTemplates.first { $0.id == selectedTemplateID }
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedWhy: String {
        whyItMatters.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedFallback: String {
        fallbackAction.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var estimatedCost: Double? {
        let value = estimatedCostText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !value.isEmpty else { return nil }
        return max(0, Double(value) ?? 0)
    }

    var delayProtocol: DelayProtocol {
        if protocolType == .customDate {
            return DelayProtocol(type: .customDate, customDate: customDecisionDate)
        }

        return DelayProtocol(type: protocolType)
    }

    var decisionDate: Date {
        delayProtocol.decisionDate(from: startDate)
    }

    var isValid: Bool {
        !normalizedTitle.isEmpty && decisionDate > startDate
    }

    var isDateRangeInvalid: Bool {
        decisionDate <= startDate
    }

    func makeDraft() -> DeferDraft {
        DeferDraft(
            title: normalizedTitle,
            whyItMatters: normalizedWhy,
            category: category,
            startDate: startDate,
            delayProtocol: delayProtocol,
            estimatedCost: estimatedCost,
            fallbackAction: normalizedFallback
        )
    }

    func setCategory(_ newCategory: DeferCategory) {
        guard category != newCategory else { return }
        category = newCategory
        selectedTemplateID = nil
    }

    func setProtocolType(_ newType: DelayProtocolType, calendar: Calendar = .current) {
        guard protocolType != newType else { return }
        protocolType = newType

        if newType == .customDate {
            let fallbackDate = calendar.date(byAdding: .hour, value: 24, to: startDate) ?? startDate
            customDecisionDate = max(customDecisionDate, fallbackDate)
        }
    }

    func applyTemplate(_ template: DeferTemplate, calendar: Calendar = .current) {
        selectedTemplateID = template.id
        title = template.title
        whyItMatters = template.whyItMatters
        fallbackAction = template.fallbackAction
        if let suggestedCost = template.suggestedCost {
            estimatedCostText = String(format: "%.2f", suggestedCost)
        }

        let normalizedStart = calendar.startOfDay(for: startDate)
        startDate = normalizedStart
        protocolType = template.protocolType
        if template.protocolType == .customDate {
            customDecisionDate = calendar.date(byAdding: .hour, value: template.durationHours, to: normalizedStart) ?? customDecisionDate
        }
    }
}
