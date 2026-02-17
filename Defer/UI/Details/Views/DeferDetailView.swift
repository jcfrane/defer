import SwiftUI
import Combine

struct DeferDetailView: View {
    let item: DeferItem
    let onCheckIn: () -> Void
    let onTogglePause: () -> Void
    let onMarkFailed: () -> Void
    let onEdit: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var atmosphereTime: TimeInterval = 0
    @StateObject private var viewModel = DeferDetailViewModel()

    private var progress: Double { viewModel.progress(for: item) }
    private var daysRemaining: Int { viewModel.daysRemaining(for: item) }
    private let failAccent = Color(red: 0.86, green: 0.28, blue: 0.24)
    private let atmosphereTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private var checkInCount: Int {
        viewModel.checkInCount(for: item)
    }

    private var pauseCount: Int {
        viewModel.pauseCount(for: item)
    }

    private var failCount: Int {
        viewModel.failCount(for: item)
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

                                    Text(item.status.displayName)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(DeferTheme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(DeferTheme.statusColor(for: item.status).opacity(0.92)))
                                }
                            }
                        )

                        momentumHero
                    }
                    .padding(.horizontal, DeferTheme.spacing(1.5))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 80)
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
            .onReceive(atmosphereTimer) { tick in
                atmosphereTime = tick.timeIntervalSinceReferenceDate
            }
        }
    }

    private var detailAtmosphere: some View {
        return GeometryReader { proxy in
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

    private var momentumHero: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.5)) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(daysRemaining == 1 ? "1 day left" : "\(daysRemaining) days left")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(DeferTheme.textPrimary)

                    Text("Streak \(item.streakCount) • Strict mode \(item.strictMode ? "On" : "Off")")
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
                                colors: [
                                    DeferTheme.success,
                                    DeferTheme.warning,
                                    DeferTheme.accent
                                ],
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

            if let details = item.details, !details.isEmpty {
                Text(details)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.86))
                    .lineLimit(4)
            }

            HStack(spacing: DeferTheme.spacing(0.75)) {
                statChip(
                    label: "Check-ins",
                    value: checkInCount,
                    color: DeferTheme.success,
                    icon: "checkmark.circle.fill"
                )
                statChip(
                    label: "Paused",
                    value: pauseCount,
                    color: DeferTheme.warning,
                    icon: "pause.fill"
                )
                statChip(
                    label: "Failed",
                    value: failCount,
                    color: failAccent,
                    icon: "xmark.circle.fill",
                    emphasized: true
                )
            }

            Divider()
                .overlay(Color.white.opacity(0.14))

            VStack(alignment: .leading, spacing: DeferTheme.spacing(1)) {
                Text("Consistency Heatmap")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                DeferContributionChartView(item: item)
            }
        }
        .padding(.vertical, DeferTheme.spacing(1))
    }

    private var bottomActionBar: some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            bottomActionButton(
                title: item.hasCheckedIn() ? "Checked" : "Check In",
                icon: item.hasCheckedIn() ? "checkmark.circle.fill" : "checkmark.circle",
                color: DeferTheme.success,
                disabled: viewModel.isCheckInDisabled(for: item),
                action: onCheckIn
            )

            bottomActionButton(
                title: item.status == .paused ? "Resume" : "Pause",
                icon: item.status == .paused ? "play.fill" : "pause.fill",
                color: DeferTheme.warning,
                disabled: viewModel.isPauseDisabled(for: item),
                action: onTogglePause
            )

            bottomActionButton(
                title: "Fail",
                icon: "xmark.circle",
                color: failAccent,
                disabled: viewModel.isFailDisabled(for: item),
                action: onMarkFailed
            )
        }
        .padding(.horizontal, DeferTheme.spacing(1))
        .padding(.top, DeferTheme.spacing(1))
        .padding(.bottom, DeferTheme.spacing(1.5))
        .background(Color.clear)
    }

    private func statChip(
        label: String,
        value: Int,
        color: Color,
        icon: String,
        emphasized: Bool = false
    ) -> some View {
        let fill = Color.white.opacity(0.08)
        let stroke = Color.white.opacity(0.16)
        let valueColor = emphasized ? color : DeferTheme.textPrimary

        return VStack(alignment: .leading, spacing: 2) {
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
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(stroke, lineWidth: 1)
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
}

#Preview {
    let bundle = PreviewFixtures.sampleBundle()

    return DeferDetailView(
        item: bundle.activeItems[0],
        onCheckIn: {},
        onTogglePause: {},
        onMarkFailed: {},
        onEdit: {}
    )
}
