import SwiftUI
import Combine

struct DeferDetailView: View {
    let item: DeferItem
    let showWhyReminderPrompt: Bool
    let reflectionPromptEnabled: Bool
    let onLogUrge: () -> Void
    let onUseFallback: () -> Void
    let onDeleteUrge: (UrgeLog) -> Void
    let onDecideOutcome: (DecisionOutcome, String?) -> Void
    let onPostpone: (DelayProtocol, String?) -> Void
    let onMarkGaveIn: () -> Void
    let onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var atmosphereTime: TimeInterval = 0
    @State private var showingDecisionSheet = false
    @State private var showingPostponeSheet = false
    @StateObject private var viewModel = DeferDetailViewModel()

    private var progress: Double { viewModel.progress(for: item) }
    private var recentUrges: [UrgeLog] { viewModel.recentUrges(for: item) }
    private let atmosphereTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var urgencyLabel: String {
        if item.isCheckpointDue(referenceDate: .now) {
            return "Checkpoint due now"
        }

        let hours = viewModel.hoursRemaining(for: item)
        if hours < 24 {
            return "\(hours) hours remaining"
        }

        let days = viewModel.daysRemaining(for: item)
        return "\(days) days remaining"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                detailAtmosphere

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DeferTheme.spacing(2)) {
                        AppPageHeaderView(
                            title: item.title,
                            subtitle: {
                                HStack(spacing: DeferTheme.spacing(0.75)) {
                                    Label(item.category.displayName, systemImage: DeferTheme.categoryIcon(for: item.category))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(DeferTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(DeferTheme.surface.opacity(0.65)))

                                    Text(item.status.normalizedLifecycle.displayName)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(DeferTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(DeferTheme.statusColor(for: item.status.normalizedLifecycle).opacity(0.92)))
                                }
                            }
                        )

                        checkpointHero
                    }
                    .padding(.horizontal, DeferTheme.spacing(1.5))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 110)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActionBar
            }
            .sheet(isPresented: $showingDecisionSheet) {
                decisionSheet
            }
            .sheet(isPresented: $showingPostponeSheet) {
                postponeSheet
            }
            .onReceive(atmosphereTimer) { tick in
                atmosphereTime = tick.timeIntervalSinceReferenceDate
            }
        }
    }

    private var detailAtmosphere: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let t = atmosphereTime
            let driftA = CGFloat(sin(t * 0.14))
            let driftB = CGFloat(cos(t * 0.11))
            let driftC = CGFloat(sin(t * 0.09))
            let driftD = CGFloat(cos(t * 0.17))

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DeferTheme.success.opacity(0.18), .clear],
                            center: .center,
                            startRadius: 6,
                            endRadius: 220
                        )
                    )
                    .frame(width: 360, height: 360)
                    .position(
                        x: (size.width * 0.5) + (driftA * size.width * 0.46),
                        y: (size.height * 0.14) + (driftB * size.height * 0.08)
                    )
                    .scaleEffect(1 + (driftC * 0.08))
                    .blur(radius: 10)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DeferTheme.warning.opacity(0.22), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 260
                        )
                    )
                    .frame(width: 420, height: 420)
                    .position(
                        x: (size.width * 0.5) + (driftD * size.width * 0.44),
                        y: (size.height * 0.04) + (driftA * size.height * 0.09)
                    )
                    .scaleEffect(1 + (driftB * 0.07))
                    .blur(radius: 11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
    }

    private var checkpointHero: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(urgencyLabel)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text("Protocol: \(item.delayProtocolType.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 7)
                        .frame(width: 72, height: 72)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                colors: [DeferTheme.success, DeferTheme.warning, DeferTheme.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)
                }
                .padding(.top, DeferTheme.spacing(0.75))
            }

            if let reason = item.whyItMatters, !reason.isEmpty {
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.86))
                    .lineLimit(4)
            }

            if showWhyReminderPrompt {
                whyReminderCard
            }

            HStack(spacing: DeferTheme.spacing(0.75)) {
                statChip(
                    label: "Urges",
                    value: viewModel.urgeCount(for: item),
                    color: DeferTheme.warning,
                    icon: "waveform.path.ecg"
                )
                statChip(
                    label: "Fallback",
                    value: viewModel.fallbackUsageCount(for: item),
                    color: DeferTheme.success,
                    icon: "shield.checkered"
                )
                statChip(
                    label: "Avg Intensity",
                    value: Int(viewModel.averageUrgeIntensity(for: item).rounded()),
                    color: DeferTheme.accent,
                    icon: "gauge"
                )
            }
            
            if let fallback = item.fallbackAction,
               !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                fallbackCard(fallback)
            }

            VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                Text("Consistency Heatmap")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                DeferContributionChartView(item: item)
            }

            DeferRecentUrgesCardView(
                urgeLogs: recentUrges,
                onDeleteUrge: onDeleteUrge
            )
        
        }
        .padding(.vertical, DeferTheme.spacing(1))
    }

    private var bottomActionBar: some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            bottomActionButton(
                title: "Log Urge",
                icon: "waveform.path.ecg",
                color: DeferTheme.success,
                disabled: viewModel.isLogUrgeDisabled(for: item),
                action: onLogUrge
            )

            bottomActionButton(
                title: "Fallback",
                icon: "shield.checkered",
                color: DeferTheme.accent,
                disabled: viewModel.isLogUrgeDisabled(for: item),
                action: onUseFallback
            )

            bottomActionButton(
                title: "Decide",
                icon: "checkmark.circle",
                color: DeferTheme.warning,
                disabled: viewModel.isDecisionDisabled(for: item),
                action: { showingDecisionSheet = true }
            )

            bottomActionButton(
                title: "Postpone",
                icon: "calendar.badge.clock",
                color: DeferTheme.warning.opacity(0.85),
                disabled: viewModel.isDecisionDisabled(for: item),
                action: { showingPostponeSheet = true }
            )
        }
        .padding(.horizontal, DeferTheme.spacing(1))
        .padding(.top, DeferTheme.spacing(1))
        .padding(.bottom, DeferTheme.spacing(1.5))
        .background(Color.clear)
    }

    private var decisionSheet: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
                        Text("Decision Outcome")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DeferTheme.textPrimary)

                        VStack(spacing: DeferTheme.spacing(0.75)) {
                            ForEach([DecisionOutcome.resisted, .intentionalYes, .gaveIn, .canceled], id: \.id) { outcome in
                                Button {
                                    viewModel.selectedOutcome = outcome
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(outcome.displayName)
                                                .font(.subheadline.weight(.semibold))
                                            Text(outcomeCopy(for: outcome))
                                                .font(.caption)
                                                .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                                        }
                                        .foregroundStyle(DeferTheme.textPrimary)

                                        Spacer()

                                        Image(systemName: viewModel.selectedOutcome == outcome ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(DeferTheme.outcomeColor(for: outcome))
                                    }
                                    .padding(DeferTheme.spacing(1.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if reflectionPromptEnabled {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reflection (optional)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

                                TextField("What influenced this choice?", text: $viewModel.reflection, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.black.opacity(0.15))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                            )
                                    )
                                    .foregroundStyle(DeferTheme.textPrimary)
                            }
                        }
                    }
                    .padding(DeferTheme.spacing(2))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        showingDecisionSheet = false
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onDecideOutcome(
                            viewModel.selectedOutcome,
                            viewModel.reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : viewModel.reflection
                        )
                        viewModel.clearDraftInputs()
                        showingDecisionSheet = false
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(role: .destructive) {
                    onMarkGaveIn()
                    showingDecisionSheet = false
                } label: {
                    Text("Record gave in")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(DeferTheme.danger.opacity(0.9)))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DeferTheme.spacing(2))
                .padding(.vertical, DeferTheme.spacing(1.25))
                .background(Color.black.opacity(0.2))
            }
        }
    }

    private var postponeSheet: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
                    Text("Postpone Checkpoint")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)

                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: DeferTheme.spacing(0.75)) {
                        ForEach(DelayProtocolType.allCases) { type in
                            Button {
                                viewModel.postponeProtocolType = type
                            } label: {
                                Text(type.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DeferTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(viewModel.postponeProtocolType == type ? DeferTheme.success.opacity(0.5) : Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.postponeProtocolType == .customDate {
                        DatePicker(
                            "Decision not before",
                            selection: $viewModel.postponeCustomDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .tint(DeferTheme.accent)
                        .foregroundStyle(DeferTheme.textPrimary)
                    }

                    TextField("Optional note", text: $viewModel.postponeNote, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(DeferTheme.textPrimary)

                    Spacer(minLength: 0)
                }
                .padding(DeferTheme.spacing(2))
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        showingPostponeSheet = false
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        onPostpone(
                            viewModel.postponeProtocol(),
                            viewModel.postponeNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : viewModel.postponeNote
                        )
                        viewModel.clearDraftInputs()
                        showingPostponeSheet = false
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                }
            }
        }
    }

    private func statChip(
        label: String,
        value: Int,
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                    .lineLimit(1)
            }

            Text("\(value)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(DeferTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func bottomActionButton(
        title: String,
        icon: String,
        color: Color,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .foregroundStyle(DeferTheme.textPrimary)
        .background(Capsule().fill(color.opacity(disabled ? 0.35 : 0.95)))
        .disabled(disabled)
    }

    private var whyReminderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Why this matters", systemImage: "quote.bubble.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DeferTheme.warning)

            if let reason = item.whyItMatters,
               !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textPrimary.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No reason added yet. Add one in Edit so future checkpoints have better context.")
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(1.25))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func fallbackCard(_ fallback: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Fallback action", systemImage: "shield.checkered")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DeferTheme.success)

            Text(fallback)
                .font(.footnote)
                .foregroundStyle(DeferTheme.textPrimary.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(1.1))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private func outcomeCopy(for outcome: DecisionOutcome) -> String {
        switch outcome {
        case .resisted:
            return "I chose not to act on this urge."
        case .intentionalYes:
            return "I still chose yes after the delay."
        case .postponed:
            return "Move checkpoint to a new protocol."
        case .gaveIn:
            return "I acted before the plan held."
        case .canceled:
            return "This intent is no longer relevant."
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let item = PreviewFixtures.sampleDefer(
        title: "Impulse order",
        details: "Pause before buying. Use fallback first.",
        category: .spending,
        status: .activeWait,
        strictMode: false,
        streakCount: 0,
        startDate: calendar.date(byAdding: .day, value: -14, to: now) ?? now,
        targetDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now
    )
    item.fallbackAction = "Add it to wishlist and wait 24h."

    item.streakRecords = [
        StreakRecord(
            date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            status: .success,
            createdAt: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
            deferItem: item
        ),
        StreakRecord(
            date: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
            status: .skipped,
            createdAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
            deferItem: item
        )
    ]

    item.urgeLogs = [
        UrgeLog(
            deferID: item.id,
            loggedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
            intensity: 4,
            note: "Saw sale banner",
            usedFallbackAction: true,
            deferItem: item
        ),
        UrgeLog(
            deferID: item.id,
            loggedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            intensity: 3,
            note: "Browsing habit",
            usedFallbackAction: false,
            deferItem: item
        )
    ]

    return DeferDetailView(
        item: item,
        showWhyReminderPrompt: true,
        reflectionPromptEnabled: true,
        onLogUrge: {},
        onUseFallback: {},
        onDeleteUrge: { _ in },
        onDecideOutcome: { _, _ in },
        onPostpone: { _, _ in },
        onMarkGaveIn: {},
        onEdit: {}
    )
}
