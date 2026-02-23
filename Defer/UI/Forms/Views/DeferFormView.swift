import SwiftUI

struct DeferDraft {
    var title: String
    var whyItMatters: String
    var category: DeferCategory
    var startDate: Date
    var delayProtocol: DelayProtocol
    var estimatedCost: Double?
    var fallbackAction: String
}

struct DeferFormView: View {
    enum Mode {
        case create
        case edit

        var title: String {
            switch self {
            case .create: return "Create Defer"
            case .edit: return "Edit Intent"
            }
        }

        var actionTitle: String {
            switch self {
            case .create: return "Start Defer"
            case .edit: return "Save"
            }
        }

        var heroTitle: String {
            switch self {
            case .create: return "Configure Defer"
            case .edit: return "Refine This Intent"
            }
        }

        var heroSubtitle: String {
            switch self {
            case .create: return "Capture what you want now, then choose a defer protocol."
            case .edit: return "Adjust protocol, reason, and fallback so the next checkpoint is clear."
            }
        }

        var heroIcon: String {
            switch self {
            case .create: return "hourglass"
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
                        desireSection
                        protocolSection
                        supportSection

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
                        colors: [DeferTheme.accent.opacity(0.18), .clear],
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
                        colors: [DeferTheme.success.opacity(0.18), .clear],
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
                            colors: [DeferTheme.accent.opacity(0.95), DeferTheme.warning.opacity(0.9)],
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
                        colors: [Color.white.opacity(0.13), Color.white.opacity(0.05)],
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

    private var desireSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Desire",
                subtitle: "Capture the urge with details you can use later"
            )

            formPanel {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1.1)) {
                    categoryPickerRow

                    Divider().background(Color.white.opacity(0.15))

                    labeledInput(title: "What do you want right now?", icon: "sparkles") {
                        TextField("Describe the action or purchase", text: $viewModel.title)
                            .textInputAutocapitalization(.sentences)
                    }

                    Divider().background(Color.white.opacity(0.15))

                    labeledInput(title: "Why this matters", icon: "quote.bubble") {
                        TextField(
                            "Optional but recommended",
                            text: $viewModel.whyItMatters,
                            axis: .vertical
                        )
                        .lineLimit(2...5)
                        .textInputAutocapitalization(.sentences)
                    }

                    if viewModel.category == .spending {
                        Divider().background(Color.white.opacity(0.15))

                        labeledInput(title: "Estimated cost (optional)", icon: "dollarsign.circle") {
                            TextField("0.00", text: $viewModel.estimatedCostText)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
            }

            templateScroller
        }
    }

    private var protocolSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Defer Protocol",
                subtitle: "Pick how long to wait before deciding."
            )

            formPanel {
                VStack(alignment: .leading, spacing: DeferTheme.spacing(1.1)) {
                    protocolPickerGrid

                    if viewModel.protocolType == .customDate {
                        Divider().background(Color.white.opacity(0.15))

                        timelineRow(
                            title: "Decision not before",
                            icon: "calendar.badge.clock",
                            date: $viewModel.customDecisionDate
                        )
                    }

                    Divider().background(Color.white.opacity(0.15))

                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(DeferTheme.warning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Checkpoint")
                                .foregroundStyle(DeferTheme.textPrimary)
                                .font(.subheadline.weight(.semibold))

                            Text(viewModel.decisionDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                        }
                    }
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            DeferFormSectionHeaderView(
                title: "Support Plan",
                subtitle: "Define what to do when the urge spikes."
            )

            formPanel {
                labeledInput(title: "Fallback action", icon: "shield.checkered") {
                    TextField(
                        "Example: Walk for 5 minutes, then re-evaluate",
                        text: $viewModel.fallbackAction,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.sentences)
                }
            }
        }
    }

    private var categoryPickerRow: some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            DeferFormIconOrbView(systemName: DeferTheme.categoryIcon(for: viewModel.category), tint: DeferTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Category")
                    .foregroundStyle(DeferTheme.textPrimary)
                Text("Used for insights and history filters.")
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
            }

            Spacer(minLength: 0)

            Menu {
                ForEach(DeferCategory.allCases) { category in
                    Button(category.displayName) {
                        AppHaptics.selection()
                        viewModel.setCategory(category)
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
                .background(Capsule().fill(DeferTheme.accent.opacity(0.9)))
            }
        }
    }

    private var protocolPickerGrid: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
            Text("Protocol presets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

            let columns = [
                GridItem(.flexible(), spacing: DeferTheme.spacing(0.75)),
                GridItem(.flexible(), spacing: DeferTheme.spacing(0.75))
            ]

            LazyVGrid(columns: columns, spacing: DeferTheme.spacing(0.75)) {
                ForEach(DelayProtocolType.allCases) { type in
                    protocolChip(type: type)
                }
            }
        }
    }

    private var templateScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DeferTheme.spacing(0.75)) {
                ForEach(viewModel.availableTemplates) { template in
                    Button {
                        AppHaptics.selection()
                        viewModel.applyTemplate(template)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text(template.protocolType.displayName)
                                .font(.caption2)
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.74))
                        }
                        .foregroundStyle(DeferTheme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    viewModel.selectedTemplate?.id == template.id
                                    ? DeferTheme.warning.opacity(0.48)
                                    : Color.white.opacity(0.09)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func protocolChip(type: DelayProtocolType) -> some View {
        let isSelected = viewModel.protocolType == type

        return Button {
            AppHaptics.selection()
            viewModel.setProtocolType(type)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(type == .customDate ? "Pick a date" : "Preset")
                    .font(.caption2)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            }
            .foregroundStyle(DeferTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? DeferTheme.success.opacity(0.52) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(isSelected ? 0.28 : 0.14), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var invalidDateCard: some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DeferTheme.textPrimary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(DeferTheme.danger.opacity(0.9)))

            Text("Decision checkpoint must be after the capture time.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DeferTheme.textPrimary)
        }
        .padding(DeferTheme.spacing(1.15))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.white.opacity(0.12))

            HStack {
                Spacer()

                Button {
                    AppHaptics.success()
                    onSave(viewModel.makeDraft())
                    dismiss()
                } label: {
                    Text(mode.actionTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [DeferTheme.accent.opacity(0.95), DeferTheme.warning.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .shadow(color: DeferTheme.accent.opacity(0.4), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isValid)
                .opacity(viewModel.isValid ? 1 : 0.55)
            }
            .padding(.horizontal, DeferTheme.spacing(2))
            .padding(.top, DeferTheme.spacing(1))
            .padding(.bottom, DeferTheme.spacing(1.25))
            .background(Color.black.opacity(0.2))
        }
    }

    private func formPanel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DeferTheme.spacing(1.25))
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }

    private func labeledInput<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.warning)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
            }

            content()
                .foregroundStyle(DeferTheme.textPrimary)
                .padding(.horizontal, 11)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }

    private func timelineRow(title: String, icon: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(0.8)) {
            HStack(alignment: .top, spacing: DeferTheme.spacing(1)) {
                DeferFormIconOrbView(systemName: icon, tint: DeferTheme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(DeferTheme.textPrimary)
                    Text("Choose the earliest date you'll allow a decision.")
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                }

                Spacer(minLength: 0)
            }

            DatePicker("Decision date", selection: date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.graphical)
                .tint(DeferTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }
}

extension DeferDraft {
    static func newDefault() -> DeferDraft {
        DeferDraft(
            title: "",
            whyItMatters: "",
            category: .spending,
            startDate: .now,
            delayProtocol: DelayProtocol(type: .twentyFourHours),
            estimatedCost: nil,
            fallbackAction: ""
        )
    }

    static func from(_ item: DeferItem) -> DeferDraft {
        DeferDraft(
            title: item.title,
            whyItMatters: item.whyItMatters ?? item.details ?? "",
            category: item.category,
            startDate: item.startDate,
            delayProtocol: DelayProtocol(type: item.delayProtocolType, customDate: item.delayProtocolType == .customDate ? item.targetDate : nil),
            estimatedCost: item.estimatedCost,
            fallbackAction: item.fallbackAction ?? ""
        )
    }
}

#Preview {
    DeferFormView(
        mode: .create,
        initialDraft: .newDefault(),
        onSave: { _ in }
    )
}
