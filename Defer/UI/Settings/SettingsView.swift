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

                ScrollView {
                    VStack(spacing: DeferTheme.spacing(2)) {
                        AppPageHeaderView(title: "Settings")

                        notificationCard

                        appCard
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

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            Text("Notifications")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)

            HStack {
                Text("Status")
                    .foregroundStyle(DeferTheme.textPrimary)
                Spacer()
                Text(authorizationState.summaryText)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted)
            }

            Toggle(isOn: $remindersEnabled) {
                Text("Enable reminders")
                    .foregroundStyle(DeferTheme.textPrimary)
            }

            if remindersEnabled {
                DatePicker(
                    "Reminder time",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .foregroundStyle(DeferTheme.textPrimary)
                .disabled(!canConfigureSchedules)

                Toggle(isOn: $dailyCheckInEnabled) {
                    Text("Daily check-in")
                        .foregroundStyle(DeferTheme.textPrimary)
                }
                .disabled(!canConfigureSchedules)

                Toggle(isOn: $milestoneEnabled) {
                    Text("Milestone reminders")
                        .foregroundStyle(DeferTheme.textPrimary)
                }
                .disabled(!canConfigureSchedules)

                Toggle(isOn: $targetApproachingEnabled) {
                    Text("Target-date approaching")
                        .foregroundStyle(DeferTheme.textPrimary)
                }
                .disabled(!canConfigureSchedules)
            }

            if authorizationState == .denied {
                Text("Notifications are denied. Enable them in iOS Settings.")
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted)

                Button("Open iOS Settings") {
                    openSystemSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private var notificationOnboardingSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
                Text("Stay Consistent")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text("Turn on notifications to protect your streak with check-ins, milestone nudges, and target-date reminders.")
                    .foregroundStyle(DeferTheme.textMuted)

                VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                    Label("Daily check-in reminder", systemImage: "checkmark.circle")
                    Label("Milestone progress reminders", systemImage: "flag")
                    Label("Target-date approaching alerts", systemImage: "calendar")
                }
                .foregroundStyle(DeferTheme.textPrimary)

                Spacer()

                Button("Continue") {
                    Task {
                        await continueFromNotificationOnboarding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(DeferTheme.accent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(DeferTheme.spacing(2))
            .background(DeferTheme.homeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Not now") {
                        showNotificationOnboarding = false
                    }
                    .foregroundStyle(DeferTheme.textMuted)
                }
            }
        }
    }

    private var appCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            Text("App")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)

            Toggle(isOn: .constant(true)) {
                Text("Haptics")
                    .foregroundStyle(DeferTheme.textPrimary)
            }
            .disabled(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Date(timeIntervalSinceReferenceDate: reminderTimeInterval)
            },
            set: { value in
                reminderTimeInterval = value.timeIntervalSinceReferenceDate
            }
        )
    }

    private var canConfigureSchedules: Bool {
        remindersEnabled && authorizationState == .enabled
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
            }
        }

        await syncNotifications()
    }

    private func continueFromNotificationOnboarding() async {
        showNotificationOnboarding = false
        authorizationState = await LocalNotificationManager.requestAuthorizationIfNeeded()
        if authorizationState == .enabled {
            remindersEnabled = true
        }
        await syncNotifications()
    }

    private func refreshNotificationState() async {
        authorizationState = await LocalNotificationManager.authorizationState()
    }

    private func syncNotifications() async {
        await LocalNotificationManager.syncNotifications(preferences: preferences, activeItems: activeItems)
    }

    private func openSystemSettings() {
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
