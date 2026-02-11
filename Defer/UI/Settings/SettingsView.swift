import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DeferItem.targetDate) private var deferItems: [DeferItem]

    @AppStorage("notifications.remindersEnabled") private var remindersEnabled = false
    @AppStorage("notifications.dailyCheckInEnabled") private var dailyCheckInEnabled = true
    @AppStorage("notifications.milestoneEnabled") private var milestoneEnabled = true
    @AppStorage("notifications.targetApproachingEnabled") private var targetApproachingEnabled = true
    @AppStorage("notifications.reminderTimeInterval") private var reminderTimeInterval = defaultReminderTimeInterval

    @State private var authorizationState: LocalNotificationAuthorizationState = .notDetermined
    @State private var showNotificationOnboarding = false

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
            .sheet(isPresented: $showNotificationOnboarding) {
                notificationOnboardingSheet
            }
            .task {
                await refreshNotificationState()
                await syncNotifications()
            }
            .onChange(of: remindersEnabled) { _, _ in
                Task {
                    await handleRemindersToggleChanged()
                }
            }
            .onChange(of: dailyCheckInEnabled) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: milestoneEnabled) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: targetApproachingEnabled) { _, _ in
                Task {
                    await syncNotifications()
                }
            }
            .onChange(of: reminderTimeInterval) { _, _ in
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
                    infoChip(
                        icon: "clock.fill",
                        text: reminderTimeText,
                        color: DeferTheme.warning
                    )
                    infoChip(
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

                Image(systemName: authorizationState == .enabled ? "bell.badge.fill" : "bell.slash.fill")
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

            switch authorizationState {
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
                        showNotificationOnboarding = false
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

            onboardingBenefitRow(
                icon: "checkmark.circle.fill",
                color: DeferTheme.success,
                title: "Daily check-in reminder",
                subtitle: "A gentle daily pulse to keep momentum."
            )
            onboardingBenefitRow(
                icon: "flag.fill",
                color: DeferTheme.warning,
                title: "Milestone progress reminders",
                subtitle: "Celebrate 25%, 50%, and 75% progress marks."
            )
            onboardingBenefitRow(
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
                infoChip(icon: "clock.fill", text: reminderTimeText, color: DeferTheme.warning)
                infoChip(icon: "sparkles", text: "Smart timing", color: DeferTheme.success)
                infoChip(icon: "calendar", text: "Ahead alerts", color: DeferTheme.accent)
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
                iconOrb(
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
                    iconOrb(systemName: "bell.fill", tint: DeferTheme.accent)

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

            if remindersEnabled {
                panel {
                    HStack(spacing: DeferTheme.spacing(1)) {
                        iconOrb(systemName: "clock.fill", tint: DeferTheme.warning)

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
                    iconOrb(systemName: "bell.badge", tint: DeferTheme.warning)
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
                    showNotificationOnboarding = true
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
                    iconOrb(systemName: "bell.slash.fill", tint: DeferTheme.danger)
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
                Date(timeIntervalSinceReferenceDate: reminderTimeInterval)
            },
            set: { value in
                AppHaptics.selection()
                reminderTimeInterval = value.timeIntervalSinceReferenceDate
            }
        )
    }

    private var remindersToggleBinding: Binding<Bool> {
        Binding(
            get: { remindersEnabled },
            set: { value in
                guard value != remindersEnabled else { return }
                remindersEnabled = value
                AppHaptics.impact(.light)
            }
        )
    }

    private var dailyCheckInToggleBinding: Binding<Bool> {
        Binding(
            get: { dailyCheckInEnabled },
            set: { value in
                guard value != dailyCheckInEnabled else { return }
                dailyCheckInEnabled = value
                AppHaptics.selection()
            }
        )
    }

    private var milestoneToggleBinding: Binding<Bool> {
        Binding(
            get: { milestoneEnabled },
            set: { value in
                guard value != milestoneEnabled else { return }
                milestoneEnabled = value
                AppHaptics.selection()
            }
        )
    }

    private var targetApproachingToggleBinding: Binding<Bool> {
        Binding(
            get: { targetApproachingEnabled },
            set: { value in
                guard value != targetApproachingEnabled else { return }
                targetApproachingEnabled = value
                AppHaptics.selection()
            }
        )
    }

    private var hasEnabledReminderType: Bool {
        dailyCheckInEnabled || milestoneEnabled || targetApproachingEnabled
    }

    private var enabledReminderTypeCount: Int {
        [dailyCheckInEnabled, milestoneEnabled, targetApproachingEnabled].filter { $0 }.count
    }

    private var reminderTimeText: String {
        Date(timeIntervalSinceReferenceDate: reminderTimeInterval).formatted(date: .omitted, time: .shortened)
    }

    private var reminderProfileTitle: String {
        switch authorizationState {
        case .enabled where remindersEnabled && hasEnabledReminderType:
            return "Actively guiding your streak"
        case .enabled where remindersEnabled:
            return "Schedule enabled, types muted"
        case .enabled:
            return "Permission ready, schedule off"
        case .notDetermined:
            return "Permission not requested"
        case .denied:
            return "Notifications blocked"
        case .unknown:
            return "Permission status unavailable"
        }
    }

    private var reminderProfileSubtitle: String {
        switch authorizationState {
        case .enabled where remindersEnabled && hasEnabledReminderType:
            return "You will receive focused reminders at \(reminderTimeText)."
        case .enabled where remindersEnabled:
            return "Turn on at least one reminder type to start scheduling."
        case .enabled:
            return "Enable your reminder schedule anytime from below."
        case .notDetermined:
            return "Run setup to request access and unlock reminder controls."
        case .denied:
            return "Enable notification access in iOS Settings to continue."
        case .unknown:
            return "Reopen the app or check iOS settings to refresh status."
        }
    }

    private var authorizationBadgeText: String {
        switch authorizationState {
        case .enabled:
            return "Allowed"
        case .denied:
            return "Blocked"
        case .notDetermined:
            return "Not Set"
        case .unknown:
            return "Unknown"
        }
    }

    private var authorizationHeadlineText: String {
        switch authorizationState {
        case .enabled:
            return "Permission Granted"
        case .denied:
            return "Permission Denied"
        case .notDetermined:
            return "Permission Needed"
        case .unknown:
            return "Permission Unavailable"
        }
    }

    private var authorizationIcon: String {
        switch authorizationState {
        case .enabled:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .unknown:
            return "exclamationmark.triangle.fill"
        }
    }

    private var authorizationTone: Color {
        switch authorizationState {
        case .enabled:
            return DeferTheme.success
        case .denied:
            return DeferTheme.danger
        case .notDetermined:
            return DeferTheme.warning
        case .unknown:
            return DeferTheme.warning
        }
    }

    private var authorizationDetailText: String {
        switch authorizationState {
        case .enabled:
            return "Configure your schedule and choose exactly which reminder types should reach you."
        case .denied:
            return "Defer cannot deliver reminders until you re-enable notification access in iOS Settings."
        case .notDetermined:
            return "You have not granted access yet. Run setup to start receiving reminder notifications."
        case .unknown:
            return "Unable to read notification permission status right now. Try reopening the app."
        }
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
                iconOrb(systemName: icon, tint: iconTint)

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

    private func iconOrb(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.callout.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(tint.opacity(0.18))
            )
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.17))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private func onboardingBenefitRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: DeferTheme.spacing(1)) {
            iconOrb(systemName: icon, tint: color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
            }

            Spacer(minLength: 0)
        }
        .padding(DeferTheme.spacing(1))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
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

    private var preferences: NotificationPreferences {
        NotificationPreferences(
            remindersEnabled: remindersEnabled,
            dailyCheckInEnabled: dailyCheckInEnabled,
            milestoneEnabled: milestoneEnabled,
            targetApproachingEnabled: targetApproachingEnabled,
            reminderTime: Date(timeIntervalSinceReferenceDate: reminderTimeInterval)
        )
    }

    private func handleRemindersToggleChanged() async {
        if remindersEnabled {
            let state = await LocalNotificationManager.authorizationState()
            authorizationState = state
            if state == .notDetermined {
                remindersEnabled = false
                showNotificationOnboarding = true
                await syncNotifications()
                return
            }

            if state != .enabled {
                remindersEnabled = false
                AppHaptics.warning()
            }
        }

        await syncNotifications()
    }

    private func continueFromNotificationOnboarding() async {
        showNotificationOnboarding = false
        authorizationState = await LocalNotificationManager.requestAuthorizationIfNeeded()
        if authorizationState == .enabled {
            remindersEnabled = true
            AppHaptics.success()
        } else {
            AppHaptics.warning()
        }
        await syncNotifications()
    }

    private func refreshNotificationState() async {
        authorizationState = await LocalNotificationManager.authorizationState()
        if authorizationState != .enabled && remindersEnabled {
            remindersEnabled = false
        }
    }

    private func syncNotifications() async {
        await LocalNotificationManager.syncNotifications(preferences: preferences, activeItems: activeItems)
    }

    private func openSystemSettings() {
        AppHaptics.impact(.light)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private static var defaultReminderTimeInterval: TimeInterval {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = 20
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? .now
        return date.timeIntervalSinceReferenceDate
    }
}
