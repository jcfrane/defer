import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DeferItem.targetDate) private var deferItems: [DeferItem]

    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                settingsAtmosphere

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeferTheme.spacing(2)) {
                        AppPageHeaderView(
                            title: "Settings",
                            subtitle: {
                                Text("Shape reminders around your rhythm, not your stress.")
                                    .font(.subheadline)
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                            }
                        )

                        notificationOverviewCard
                        notificationCard
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 90)
                }
            }
            .sheet(isPresented: $viewModel.showNotificationOnboarding) {
                notificationOnboardingSheet
            }
            .task {
                await refreshNotificationState()
                await syncNotifications()
            }
            .onChange(of: viewModel.remindersEnabled) { _, _ in
                Task {
                    await handleRemindersToggleChanged()
                }
            }
            .onChange(of: viewModel.dailyCheckInEnabled) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: viewModel.milestoneEnabled) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: viewModel.targetApproachingEnabled) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: viewModel.reminderTimeInterval) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: activeItemRescheduleSignature) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await refreshNotificationState()
                    await syncNotifications()
                }
            }
        }
    }

    private var settingsAtmosphere: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.accent.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 150, y: -300)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.success.opacity(0.16),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 170
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: -170, y: -180)
                .blur(radius: 7)
        }
        .allowsHitTesting(false)
    }

    private var notificationOverviewCard: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Reminder Profile")
                    .font(.caption.weight(.semibold))
                    .tracking(0.7)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.72))

                Text(reminderProfileTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(reminderProfileSubtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                    .lineLimit(2)

                HStack(spacing: DeferTheme.spacing(0.75)) {
                    SettingsInfoChipView(
                        icon: "clock.fill",
                        text: reminderTimeText,
                        color: DeferTheme.warning
                    )
                    SettingsInfoChipView(
                        icon: "bell.badge.fill",
                        text: "\(enabledReminderTypeCount) types",
                        color: DeferTheme.success
                    )
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DeferTheme.accent.opacity(0.95),
                                DeferTheme.warning.opacity(0.92)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: DeferTheme.accent.opacity(0.45), radius: 14, y: 6)

                Image(systemName: viewModel.authorizationState == .enabled ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
            }
        }
        .padding(DeferTheme.spacing(2))
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
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
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 18, y: 10)
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            HStack(alignment: .center) {
                Text("Notification Controls")
                    .font(.headline)
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer()
                authorizationBadge
            }

            authorizationSummaryCard

            switch viewModel.authorizationState {
            case .enabled:
                enabledNotificationControls
            case .notDetermined:
                notificationRequestCard
            case .denied, .unknown:
                notificationDeniedCard
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private var notificationOnboardingSheet: some View {
        ZStack {
            DeferTheme.homeBackground
                .ignoresSafeArea()

            onboardingAtmosphere

            VStack(spacing: DeferTheme.spacing(1.5)) {
                HStack {
                    Spacer()
                    Button("Not now") {
                        AppHaptics.selection()
                        viewModel.showNotificationOnboarding = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary.opacity(0.94))
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.vertical, DeferTheme.spacing(1))
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.24))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, DeferTheme.spacing(2))
                .padding(.top, DeferTheme.spacing(1))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeferTheme.spacing(1.75)) {
                        onboardingHeroCard
                        onboardingBenefitsCard
                        onboardingPreviewCard
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(0.5))
                    .padding(.bottom, DeferTheme.spacing(1))
                }

                Button {
                    AppHaptics.selection()
                    Task {
                        await continueFromNotificationOnboarding()
                    }
                } label: {
                    HStack(spacing: DeferTheme.spacing(0.75)) {
                        Text("Continue")
                            .font(.headline.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(DeferTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DeferTheme.spacing(1.4))
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
                    .shadow(color: DeferTheme.accent.opacity(0.38), radius: 12, y: 6)
                }
                .padding(.horizontal, DeferTheme.spacing(4))
                .padding(.bottom, DeferTheme.spacing(2))
            }
        }
    }

    private var onboardingAtmosphere: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.success.opacity(0.22),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 230
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: -140, y: -250)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DeferTheme.accent.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 200
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: 170, y: -300)
        }
        .blur(radius: 8)
        .allowsHitTesting(false)
    }

    private var onboardingHeroCard: some View {
        HStack(alignment: .top, spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Stay Consistent")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text("Turn on notifications to protect your streak with precise timing and lightweight nudges.")
                    .font(.body)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(DeferTheme.accent.opacity(0.9))
                    .frame(width: 58, height: 58)
                    .shadow(color: DeferTheme.accent.opacity(0.4), radius: 10, y: 5)

                Image(systemName: "bell.badge.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
            }
        }
        .padding(DeferTheme.spacing(2))
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var onboardingBenefitsCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            Text("What you get")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

            SettingsOnboardingBenefitRowView(
                icon: "checkmark.circle.fill",
                color: DeferTheme.success,
                title: "Daily check-in reminder",
                subtitle: "A gentle daily pulse to keep momentum."
            )
            SettingsOnboardingBenefitRowView(
                icon: "flag.fill",
                color: DeferTheme.warning,
                title: "Milestone progress reminders",
                subtitle: "Celebrate 25%, 50%, and 75% progress marks."
            )
            SettingsOnboardingBenefitRowView(
                icon: "calendar.badge.clock",
                color: DeferTheme.accent,
                title: "Target-date approaching alerts",
                subtitle: "Heads-up at 3 days and 1 day remaining."
            )
        }
        .padding(DeferTheme.spacing(2))
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var onboardingPreviewCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            Text("Preview")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

            HStack(spacing: DeferTheme.spacing(0.75)) {
                SettingsInfoChipView(icon: "clock.fill", text: reminderTimeText, color: DeferTheme.warning)
                SettingsInfoChipView(icon: "sparkles", text: "Smart timing", color: DeferTheme.success)
                SettingsInfoChipView(icon: "calendar", text: "Ahead alerts", color: DeferTheme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DeferTheme.spacing(1.5))
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var authorizationBadge: some View {
        HStack(spacing: DeferTheme.spacing(0.5)) {
            Image(systemName: authorizationIcon)
                .font(.caption.weight(.bold))
            Text(authorizationBadgeText)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(authorizationTone)
        .padding(.horizontal, DeferTheme.spacing(1))
        .padding(.vertical, DeferTheme.spacing(0.5))
        .background(
            Capsule()
                .fill(authorizationTone.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(authorizationTone.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var authorizationSummaryCard: some View {
        panel {
            HStack(alignment: .top, spacing: DeferTheme.spacing(1)) {
                SettingsIconOrbView(
                    systemName: authorizationIcon,
                    tint: authorizationTone
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(authorizationHeadlineText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)
                    Text(authorizationDetailText)
                        .font(.footnote)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.83))
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var enabledNotificationControls: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
            panel {
                HStack(spacing: DeferTheme.spacing(1)) {
                    SettingsIconOrbView(systemName: "bell.fill", tint: DeferTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable reminder schedule")
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text("Turn all reminders on or off in one switch.")
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                    }

                    Spacer(minLength: 0)

                    Toggle("", isOn: remindersToggleBinding)
                        .labelsHidden()
                        .tint(DeferTheme.accent)
                }
            }

            if viewModel.remindersEnabled {
                panel {
                    HStack(spacing: DeferTheme.spacing(1)) {
                        SettingsIconOrbView(systemName: "clock.fill", tint: DeferTheme.warning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder time")
                                .foregroundStyle(DeferTheme.textPrimary)
                            Text("Used by every enabled reminder type.")
                                .font(.caption)
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                        }

                        Spacer(minLength: 0)

                        DatePicker(
                            "",
                            selection: reminderTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(DeferTheme.accent)
                    }
                }

                VStack(alignment: .leading, spacing: DeferTheme.spacing(0.85)) {
                    Text("Reminder Types")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DeferTheme.textPrimary)

                    reminderTypeRow(
                        icon: "checkmark.circle.fill",
                        iconTint: DeferTheme.success,
                        title: "Daily check-in",
                        subtitle: "One reminder every day to protect your streak.",
                        isOn: dailyCheckInToggleBinding
                    )

                    reminderTypeRow(
                        icon: "flag.fill",
                        iconTint: DeferTheme.warning,
                        title: "Progress milestones",
                        subtitle: "Nudges at 25%, 50%, and 75% of each defer.",
                        isOn: milestoneToggleBinding
                    )

                    reminderTypeRow(
                        icon: "calendar.badge.clock",
                        iconTint: DeferTheme.accent,
                        title: "Target date approaching",
                        subtitle: "Alerts 3 days and 1 day before the target date.",
                        isOn: targetApproachingToggleBinding
                    )
                }

                if !hasEnabledReminderType {
                    Text("Select at least one reminder type to schedule notifications.")
                        .font(.footnote)
                        .foregroundStyle(DeferTheme.warning)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var notificationRequestCard: some View {
        panel {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                HStack(spacing: DeferTheme.spacing(1)) {
                    SettingsIconOrbView(systemName: "bell.badge", tint: DeferTheme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications are not set up yet.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text("Enable permissions and start with a clean reminder setup.")
                            .font(.footnote)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                    }
                }

                Button {
                    AppHaptics.selection()
                    viewModel.showNotificationOnboarding = true
                } label: {
                    Label("Set up notifications", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .tint(DeferTheme.accent)
            }
        }
    }

    private var notificationDeniedCard: some View {
        panel {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                HStack(spacing: DeferTheme.spacing(1)) {
                    SettingsIconOrbView(systemName: "bell.slash.fill", tint: DeferTheme.danger)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications are blocked")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text("Open iOS Settings and re-enable notifications for Defer.")
                            .font(.footnote)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.82))
                    }
                }

                Button("Open iOS Settings") {
                    openSystemSettings()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Date(timeIntervalSinceReferenceDate: viewModel.reminderTimeInterval)
            },
            set: { value in
                viewModel.setReminderTime(value)
            }
        )
    }

    private var remindersToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.remindersEnabled },
            set: { value in
                viewModel.setRemindersEnabled(value)
            }
        )
    }

    private var dailyCheckInToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.dailyCheckInEnabled },
            set: { value in
                viewModel.setDailyCheckInEnabled(value)
            }
        )
    }

    private var milestoneToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.milestoneEnabled },
            set: { value in
                viewModel.setMilestoneEnabled(value)
            }
        )
    }

    private var targetApproachingToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.targetApproachingEnabled },
            set: { value in
                viewModel.setTargetApproachingEnabled(value)
            }
        )
    }

    private var hasEnabledReminderType: Bool {
        viewModel.hasEnabledReminderType
    }

    private var enabledReminderTypeCount: Int {
        viewModel.enabledReminderTypeCount
    }

    private var reminderTimeText: String {
        viewModel.reminderTimeText
    }

    private var reminderProfileTitle: String {
        viewModel.reminderProfileTitle
    }

    private var reminderProfileSubtitle: String {
        viewModel.reminderProfileSubtitle
    }

    private var authorizationBadgeText: String {
        viewModel.authorizationBadgeText
    }

    private var authorizationHeadlineText: String {
        viewModel.authorizationHeadlineText
    }

    private var authorizationIcon: String {
        viewModel.authorizationIcon
    }

    private var authorizationTone: Color {
        viewModel.authorizationTone
    }

    private var authorizationDetailText: String {
        viewModel.authorizationDetailText
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
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

    private func reminderTypeRow(
        icon: String,
        iconTint: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        panel {
            HStack(spacing: DeferTheme.spacing(1)) {
                SettingsIconOrbView(systemName: icon, tint: iconTint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(DeferTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                }

                Spacer(minLength: 0)

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(DeferTheme.accent)
            }
        }
    }

    private var activeItems: [DeferItem] {
        deferItems.filter { $0.status == .active }
    }

    private var activeItemRescheduleSignature: [String] {
        activeItems
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { item in
                [
                    item.id.uuidString,
                    String(item.targetDate.timeIntervalSinceReferenceDate),
                    String(item.startDate.timeIntervalSinceReferenceDate),
                    String(item.updatedAt.timeIntervalSinceReferenceDate)
                ].joined(separator: "|")
            }
    }

    private func handleRemindersToggleChanged() async {
        await viewModel.handleRemindersToggleChanged(activeItems: activeItems)
    }

    private func continueFromNotificationOnboarding() async {
        await viewModel.continueFromNotificationOnboarding(activeItems: activeItems)
    }

    private func refreshNotificationState() async {
        await viewModel.refreshNotificationState()
    }

    private func syncNotifications() async {
        await viewModel.syncNotifications(activeItems: activeItems)
    }

    private func openSystemSettings() {
        AppHaptics.impact(.light)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewFixtures.inMemoryContainerWithSeedData())
}
