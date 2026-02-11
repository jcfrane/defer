import SwiftUI

struct DeferDraft {
    var title: String
    var details: String
    var category: DeferCategory
    var startDate: Date
    var targetDate: Date
    var strictMode: Bool
}

struct DeferFormView: View {
    enum Mode {
        case create
        case edit

        var title: String {
            switch self {
            case .create: return "Create Defer"
            case .edit: return "Edit Defer"
            }
        }

        var actionTitle: String {
            switch self {
            case .create: return "Save"
            case .edit: return "Update"
            }
        }
    }

    let mode: Mode
    let initialDraft: DeferDraft
    let onSave: (DeferDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String
    @State private var category: DeferCategory
    @State private var startDate: Date
    @State private var targetDate: Date
    @State private var strictMode: Bool

    init(mode: Mode, initialDraft: DeferDraft, onSave: @escaping (DeferDraft) -> Void) {
        self.mode = mode
        self.initialDraft = initialDraft
        self.onSave = onSave

        _title = State(initialValue: initialDraft.title)
        _details = State(initialValue: initialDraft.details)
        _category = State(initialValue: initialDraft.category)
        _startDate = State(initialValue: initialDraft.startDate)
        _targetDate = State(initialValue: initialDraft.targetDate)
        _strictMode = State(initialValue: initialDraft.strictMode)
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetDate > startDate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you deferring?") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)

                    TextField("Details (optional)", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(DeferCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section("Timeline") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("Target", selection: $targetDate, displayedComponents: .date)

                    if targetDate <= startDate {
                        Label("Target date must be later than start date.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(DeferTheme.danger)
                            .font(.subheadline)
                    }
                }

                Section("Rules") {
                    Toggle("Strict mode", isOn: $strictMode)
                    Text(strictMode ? "You must check in daily. Missing a day marks this defer as failed." : "Check-ins are optional. This defer only ends when you manually mark it failed or it reaches target date.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.actionTitle) {
                        let draft = DeferDraft(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            startDate: startDate,
                            targetDate: targetDate,
                            strictMode: strictMode
                        )
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

extension DeferDraft {
    static func newDefault() -> DeferDraft {
        let start = Calendar.current.startOfDay(for: .now)
        let target = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start

        return DeferDraft(
            title: "",
            details: "",
            category: .habit,
            startDate: start,
            targetDate: target,
            strictMode: true
        )
    }

    static func from(_ item: DeferItem) -> DeferDraft {
        DeferDraft(
            title: item.title,
            details: item.details ?? "",
            category: item.category,
            startDate: item.startDate,
            targetDate: item.targetDate,
            strictMode: item.strictMode
        )
    }
}
