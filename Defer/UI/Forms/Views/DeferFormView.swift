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

        var heroTitle: String {
            switch self {
            case .create: return "Shape Your Next Promise"
            case .edit: return "Refine Your Promise"
            }
        }

        var heroSubtitle: String {
            switch self {
            case .create: return "Create a clear target with rules that protect your intent."
            case .edit: return "Adjust your target and rules while keeping your momentum."
            }
        }

        var heroIcon: String {
            switch self {
            case .create: return "plus.circle.fill"
            case .edit: return "slider.horizontal.3"
            }
        }
    }

    let mode: Mode
    let initialDraft: DeferDraft
    let onSave: (DeferDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: DeferFormViewModel

    init(mode: Mode, initialDraft: DeferDraft, onSave: @escaping (DeferDraft) -> Void) {
        self.mode = mode
        self.initialDraft = initialDraft
        self.onSave = onSave

        _viewModel = StateObject(wrappedValue: DeferFormViewModel(initialDraft: initialDraft))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                formAtmosphere

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DeferTheme.spacing(1.75)) {
                        formHeroCard
                        goalSection
                        classificationSection
                        timelineSection
                        rulesSection

                        if viewModel.isDateRangeInvalid {
                            invalidDateCard
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        AppHaptics.selection()
                        dismiss()
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveBar
            }
        }
    }

    private var formAtmosphere: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.accent.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 190
                    )
                )
                .frame(width: 340, height: 340)
                .offset(x: 170, y: -280)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.success.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 170
                    )
                )
                .frame(width: 310, height: 310)
                .offset(x: -170, y: -150)
                .blur(radius: 7)
        }
        .allowsHitTesting(false)
    }

    private var formHeroCard: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.7)) {
                Text(mode.heroTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(mode.heroSubtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DeferTheme.accent.opacity(0.95),
                                DeferTheme.warning.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                    .shadow(color: DeferTheme.accent.opacity(0.4), radius: 12, y: 6)

                Image(systemName: mode.heroIcon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
            }
        }
        .padding(DeferTheme.spacing(2))
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.13),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 16, y: 10)
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Goal",
                subtitle: "Give your defer a clear and specific framing."
            )

            formPanel {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1.1)) {
                    labeledInput(title: "Title", icon: "textformat") {
                        TextField("What are you deferring?", text: $viewModel.title)
                            .textInputAutocapitalization(.sentences)
                    }

                    Divider()
                        .background(Color.white.opacity(0.15))

                    labeledInput(title: "Details", icon: "note.text") {
                        TextField(
                            "Optional notes, context, or reason...",
                            text: $viewModel.details,
                            axis: .vertical
                        )
                        .lineLimit(2...5)
                        .textInputAutocapitalization(.sentences)
                    }
                }
            }
        }
    }

    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Classification",
                subtitle: "Choose where this defer belongs."
            )

            formPanel {
                HStack(spacing: DeferTheme.spacing(1)) {
                    DeferFormIconOrbView(systemName: DeferTheme.categoryIcon(for: viewModel.category), tint: DeferTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Category")
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text("Used for filtering and achievement tracking.")
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                    }

                    Spacer(minLength: 0)

                    Menu {
                        ForEach(DeferCategory.allCases) { category in
                            Button(category.displayName) {
                                AppHaptics.selection()
                                viewModel.category = category
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.category.displayName)
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(DeferTheme.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(DeferTheme.accent.opacity(0.9))
                        )
                    }
                }
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Timeline",
                subtitle: "Set a clear start and target date."
            )

            formPanel {
                VStack(spacing: DeferTheme.spacing(1.1)) {
                    timelineRow(
                        title: "Start date",
                        icon: "calendar.badge.plus",
                        date: $viewModel.startDate
                    )

                    Divider()
                        .background(Color.white.opacity(0.15))

                    timelineRow(
                        title: "Target date",
                        icon: "calendar.badge.clock",
                        date: $viewModel.targetDate
                    )
                }
            }
        }
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Rules",
                subtitle: "Choose how strict daily accountability should be."
            )

            formPanel {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                    HStack(spacing: DeferTheme.spacing(1)) {
                        DeferFormIconOrbView(systemName: "shield.lefthalf.filled", tint: DeferTheme.warning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Strict mode")
                                .foregroundStyle(DeferTheme.textPrimary)
                            Text(viewModel.strictMode ? "Daily check-in required" : "Daily check-in optional")
                                .font(.caption)
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                        }

                        Spacer(minLength: 0)

                        Toggle("", isOn: $viewModel.strictMode)
                            .labelsHidden()
                            .tint(DeferTheme.accent)
                    }

                    Divider()
                        .background(Color.white.opacity(0.15))

                    Text(
                        viewModel.strictMode
                        ? "You must check in daily. Missing a day marks this defer as failed."
                        : "Check-ins are optional. This defer only ends when you manually mark it failed or it reaches target date."
                    )
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var invalidDateCard: some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DeferTheme.textPrimary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(DeferTheme.danger.opacity(0.9))
                )

            Text("Target date must be later than start date.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(DeferTheme.textPrimary)
        }
        .padding(DeferTheme.spacing(1.25))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DeferTheme.danger.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(DeferTheme.danger.opacity(0.5), lineWidth: 1)
                )
        )
    }

    private var saveBar: some View {
        VStack(spacing: DeferTheme.spacing(1)) {
            Button {
                let draft = viewModel.makeDraft()
                AppHaptics.impact(.light)
                onSave(draft)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Text(mode.actionTitle)
                        .font(.headline.weight(.semibold))
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(DeferTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DeferTheme.spacing(1.3))
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.97, green: 0.78, blue: 0.30),
                                    Color(red: 0.85, green: 0.62, blue: 0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: DeferTheme.accent.opacity(0.35), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isValid)
            .opacity(viewModel.isValid ? 1 : 0.45)
        }
        .padding(.horizontal, DeferTheme.spacing(2))
        .padding(.top, DeferTheme.spacing(1))
        .padding(.bottom, DeferTheme.spacing(1.5))
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func formPanel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DeferTheme.spacing(1.25))
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
    }

    private func timelineRow(title: String, icon: String, date: Binding<Date>) -> some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            DeferFormIconOrbView(systemName: icon, tint: DeferTheme.warning)

            Text(title)
                .foregroundStyle(DeferTheme.textPrimary)

            Spacer(minLength: 0)

            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .tint(DeferTheme.accent)
        }
    }

    private func labeledInput<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
            }

            content()
                .foregroundStyle(DeferTheme.textPrimary)
        }
    }
}

#Preview {
    DeferFormView(
        mode: .create,
        initialDraft: .newDefault(),
        onSave: { _ in }
    )
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
            strictMode: false
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
