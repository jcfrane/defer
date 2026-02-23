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
                                Text("Keep notifications simple, tune behavior prompts, and set your currency.")
                                    .font(.subheadline)
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                            }
                        )

                        notificationCard
                        behaviorCard
                        preferencesCard
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 90)
                }
            }
            .task {
                await refreshNotificationState()
                await syncNotifications()
            }
            .onChange(of: viewModel.remindersEnabled) { _, _ in
                Task { await handleRemindersToggleChanged() }
            }
            .onChange(of: activeItemRescheduleSignature) { _, _ in
                Task { await syncNotifications() }
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
                        colors: [DeferTheme.accent.opacity(0.18), .clear],
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
                        colors: [DeferTheme.success.opacity(0.16), .clear],
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

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            HStack(alignment: .center) {
                Text("Notifications")
                    .font(.headline)
                    .foregroundStyle(DeferTheme.textPrimary)

                Spacer(minLength: 0)
                notificationBadge
            }

            panel {
                HStack(spacing: DeferTheme.spacing(1)) {
                    SettingsIconOrbView(
                        systemName: viewModel.notificationBadgeIcon,
                        tint: viewModel.notificationIconTone
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable reminders")
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text("Single on/off control for all reminder notifications.")
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                    }

                    Spacer(minLength: 0)

                    Toggle("", isOn: remindersToggleBinding)
                        .labelsHidden()
                        .tint(DeferTheme.accent)
                        .disabled(viewModel.isPermissionBlocked)
                }
            }

            Text(viewModel.notificationSummaryText)
                .font(.footnote)
                .foregroundStyle(DeferTheme.textMuted.opacity(0.82))

            if viewModel.isPermissionBlocked {
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

    private var notificationBadge: some View {
        HStack(spacing: DeferTheme.spacing(0.5)) {
            Image(systemName: viewModel.notificationBadgeIcon)
                .font(.caption.weight(.bold))
            Text(viewModel.notificationBadgeText)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(viewModel.notificationBadgeTone)
        .padding(.horizontal, DeferTheme.spacing(1))
        .padding(.vertical, DeferTheme.spacing(0.5))
        .background(
            Capsule()
                .fill(viewModel.notificationBadgeTone.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(viewModel.notificationBadgeTone.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var behaviorCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            Text("Decision Behavior")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)

            settingsToggleRow(
                icon: "text.book.closed.fill",
                iconTint: DeferTheme.textPrimary,
                title: "Prompt for reflection",
                subtitle: "Ask for a short reflection when recording outcomes.",
                isOn: reflectionPromptToggleBinding
            )

            settingsToggleRow(
                icon: "quote.bubble.fill",
                iconTint: DeferTheme.warning,
                title: "Show why-it-matters reminders",
                subtitle: "Display your reason in Home and Detail as a focus prompt.",
                isOn: whyReminderToggleBinding
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
    }

    private var remindersToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.remindersEnabled },
            set: { value in viewModel.setRemindersEnabled(value) }
        )
    }

    private var reflectionPromptToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.reflectionPromptEnabled },
            set: { value in viewModel.setReflectionPromptEnabled(value) }
        )
    }

    private var whyReminderToggleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.whyReminderEnabled },
            set: { value in viewModel.setWhyReminderEnabled(value) }
        )
    }

    private var currencyBinding: Binding<String> {
        Binding(
            get: { viewModel.currencyCode },
            set: { value in viewModel.setCurrencyCode(value) }
        )
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            Text("Preferences")
                .font(.headline)
                .foregroundStyle(DeferTheme.textPrimary)

            panel {
                HStack(spacing: DeferTheme.spacing(1)) {
                    SettingsIconOrbView(
                        systemName: "dollarsign.circle.fill",
                        tint: DeferTheme.accent
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Currency")
                            .foregroundStyle(DeferTheme.textPrimary)
                        Text("Used for estimated cost and spend-avoided values.")
                            .font(.caption)
                            .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
                    }

                    Spacer(minLength: 0)

                    Picker("Currency", selection: currencyBinding) {
                        ForEach(viewModel.currencyOptions) { option in
                            Text(option.displayName)
                                .tag(option.code)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(DeferTheme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DeferTheme.spacing(2.25))
        .glassCard()
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

    private func settingsToggleRow(
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
        deferItems.filter {
            let status = $0.status.normalizedLifecycle
            return status == .activeWait || status == .checkpointDue
        }
    }

    private var activeItemRescheduleSignature: [String] {
        activeItems
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { item in
                [
                    item.id.uuidString,
                    String(item.targetDate.timeIntervalSinceReferenceDate),
                    String(item.startDate.timeIntervalSinceReferenceDate),
                    String(item.updatedAt.timeIntervalSinceReferenceDate),
                    item.delayProtocolType.rawValue,
                    String(item.postponeCount)
                ].joined(separator: "|")
            }
    }

    private func handleRemindersToggleChanged() async {
        await viewModel.handleRemindersToggleChanged(activeItems: activeItems)
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
