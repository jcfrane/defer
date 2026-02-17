import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \Achievement.unlockedAt, order: .reverse)
    private var unlockedAchievements: [Achievement]

    @Query(sort: \CompletionHistory.completedAt)
    private var completions: [CompletionHistory]

    @Query(sort: \DeferItem.updatedAt)
    private var defers: [DeferItem]

    @State private var showcasedBadgeKey: String?

    private var unlockedByKey: [String: Achievement] {
        Dictionary(uniqueKeysWithValues: unlockedAchievements.map { ($0.key, $0) })
    }

    private var progress: AchievementProgress {
        AchievementProgress.from(defers: defers, completions: completions)
    }

    private var unlockedDefinitions: [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedByKey[$0.key] != nil }
    }

    private var lockedDefinitions: [AchievementDefinition] {
        AchievementCatalog.all.filter { unlockedByKey[$0.key] == nil }
    }

    private var completionRatio: Double {
        guard !AchievementCatalog.all.isEmpty else { return 0 }
        return Double(unlockedAchievements.count) / Double(AchievementCatalog.all.count)
    }

    private var badgeColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: DeferTheme.spacing(1.25), alignment: .top)]
    }

    private var showcasedDefinition: AchievementDefinition? {
        guard let showcasedBadgeKey else { return nil }
        return AchievementCatalog.definition(for: showcasedBadgeKey)
    }

    private var showcasedAchievement: Achievement? {
        guard let showcasedBadgeKey else { return nil }
        return unlockedByKey[showcasedBadgeKey]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeferTheme.homeBackground
                    .ignoresSafeArea()

                achievementsAtmosphere

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DeferTheme.spacing(1.75)) {
                        AppPageHeaderView(
                            title: "Achievements",
                            subtitle: {
                                Text("Every streak leaves a visible mark.")
                                    .font(.subheadline)
                                    .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                            }
                        )

                        summaryCard

                        if !unlockedDefinitions.isEmpty {
                            sectionHeader(
                                title: "Unlocked",
                                subtitle: "\(unlockedDefinitions.count) collected",
                                icon: "sparkles",
                                iconColor: DeferTheme.success
                            )

                            Text("Tap any badge to preview it in the center. Drag to rotate.")
                                .font(.caption)
                                .foregroundStyle(DeferTheme.textMuted.opacity(0.78))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            badgeGrid(definitions: unlockedDefinitions)
                        }

                        if !lockedDefinitions.isEmpty {
                            sectionHeader(
                                title: "In Progress",
                                subtitle: "\(lockedDefinitions.count) to go",
                                icon: "lock.fill",
                                iconColor: DeferTheme.warning
                            )

                            badgeGrid(definitions: lockedDefinitions)
                        }
                    }
                    .padding(.horizontal, DeferTheme.spacing(2))
                    .padding(.top, DeferTheme.spacing(1.5))
                    .padding(.bottom, 84)
                }

                if let showcasedDefinition {
                    AchievementShowcaseOverlay(
                        definition: showcasedDefinition,
                        unlocked: showcasedAchievement
                    ) {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            showcasedBadgeKey = nil
                        }
                    }
                    .zIndex(20)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showcasedBadgeKey)
    }

    private func badgeGrid(definitions: [AchievementDefinition]) -> some View {
        LazyVGrid(columns: badgeColumns, spacing: DeferTheme.spacing(1.25)) {
            ForEach(definitions) { definition in
                AchievementBadgeTile(
                    definition: definition,
                    unlocked: unlockedByKey[definition.key],
                    progress: progress
                ) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) {
                        showcasedBadgeKey = definition.key
                    }
                }
            }
        }
    }

    private var achievementsAtmosphere: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.36, green: 0.18, blue: 0.94).opacity(0.33),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 380, height: 380)
                .offset(x: 170, y: -280)
                .blur(radius: 10)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.08, green: 0.76, blue: 0.96).opacity(0.24),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 340, height: 340)
                .offset(x: -180, y: -150)
                .blur(radius: 9)
        }
        .allowsHitTesting(false)
    }

    private var summaryCard: some View {
        HStack(spacing: DeferTheme.spacing(1.5)) {
            VStack(alignment: .leading, spacing: DeferTheme.spacing(0.75)) {
                Text("Badge Vault")
                    .font(.caption.weight(.semibold))
                    .tracking(0.7)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.72))

                Text(summaryTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)

                Text(summarySubtitle)
                    .font(.footnote)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))

                HStack(spacing: DeferTheme.spacing(0.75)) {
                    statChip(icon: "rosette", text: "\(unlockedAchievements.count) unlocked", color: DeferTheme.success)
                    statChip(icon: "flag.checkered", text: "\(AchievementCatalog.all.count) total", color: DeferTheme.warning)
                }
            }

            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.88, green: 0.26, blue: 0.95),
                                Color(red: 0.26, green: 0.42, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .shadow(color: Color(red: 0.44, green: 0.30, blue: 1.0).opacity(0.45), radius: 14, y: 6)

                VStack(spacing: 2) {
                    Text("\(Int((completionRatio * 100).rounded()))%")
                        .font(.title3.weight(.bold))
                    Text("complete")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
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

    private var summaryTitle: String {
        if unlockedAchievements.isEmpty {
            return "Your first badge is waiting"
        }
        if unlockedAchievements.count == AchievementCatalog.all.count {
            return "Full collection complete"
        }
        return "Collection is growing steadily"
    }

    private var summarySubtitle: String {
        if unlockedAchievements.isEmpty {
            return "Complete your first defer to unlock your first achievement."
        }
        return "\(progress.completionCount) completions and a best streak of \(progress.maxStreak) days."
    }

    private func sectionHeader(title: String, subtitle: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: DeferTheme.spacing(1)) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.2))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(DeferTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.75))
            }

            Spacer()
        }
        .padding(.top, DeferTheme.spacing(0.5))
    }

    private func statChip(icon: String, text: String, color: Color) -> some View {
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
}

private struct AchievementBadgeTile: View {
    let definition: AchievementDefinition
    let unlocked: Achievement?
    let progress: AchievementProgress
    let onTapUnlocked: () -> Void

    private var isUnlocked: Bool { unlocked != nil }

    private var progressTuple: (current: Int, target: Int) {
        definition.rule.progressValue(using: progress)
    }

    private var progressFraction: Double {
        guard progressTuple.target > 0 else { return 0 }
        return min(Double(progressTuple.current) / Double(progressTuple.target), 1)
    }

    var body: some View {
        Button(action: onTapUnlocked) {
            tileBody
        }
        .buttonStyle(.plain)
        .accessibilityLabel(definition.title)
        .accessibilityHint(
            isUnlocked
                ? "Shows this unlocked badge in the center and lets you rotate it."
                : "Shows a locked preview in the center and lets you rotate it."
        )
    }

    private var tileBody: some View {
        VStack(spacing: DeferTheme.spacing(0.9)) {
            AchievementBadgeArtwork(
                definition: definition,
                isUnlocked: isUnlocked,
                size: 124
            )

            if let unlocked {
                Text("Unlocked \(unlocked.unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(DeferTheme.success)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 32)
            } else {
                VStack(spacing: 6) {
                    Text(definition.rule.progressText(using: progress))
                        .font(.caption2)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.84))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(minHeight: 32)

                    ProgressView(value: progressFraction)
                        .tint(Color(red: 0.96, green: 0.62, blue: 0.12))
                        .scaleEffect(x: 1, y: 1.2, anchor: .center)
                }
            }

            tierChip
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 248, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isUnlocked
                            ? [Color.white.opacity(0.14), Color.white.opacity(0.07)]
                            : [Color.white.opacity(0.09), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(isUnlocked ? 0.22 : 0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(isUnlocked ? 0.25 : 0.15), radius: isUnlocked ? 14 : 8, y: isUnlocked ? 8 : 5)
    }

    private var tierChip: some View {
        Text(definition.tier.displayName.uppercased())
            .font(.caption2.weight(.black))
            .tracking(0.9)
            .foregroundStyle(Color.white.opacity(0.92))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

private struct AchievementBadgeArtwork: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    let size: CGFloat
    var glowBoost: CGFloat = 1

    private var palette: AchievementBadgePalette {
        AchievementBadgePalette.forKey(definition.key, tier: definition.tier)
    }

    private enum BadgeMotif {
        case rings
        case rays
        case stripes
        case constellation
    }

    private var motif: BadgeMotif {
        switch definition.key {
        case "first_completion", "category_mastery_3":
            return .rings
        case "streak_7", "streak_100":
            return .rays
        case "streak_30", "completion_run_3":
            return .stripes
        case "category_mastery_10", "completion_run_7":
            return .constellation
        default:
            return .rings
        }
    }

    private var ribbonLabel: String {
        switch definition.key {
        case "first_completion":
            return "FIRST WIN"
        case "streak_7":
            return "7-DAY"
        case "streak_30":
            return "30-DAY"
        case "streak_100":
            return "100-DAY"
        case "category_mastery_3":
            return "SPECIALIST"
        case "category_mastery_10":
            return "MASTER"
        case "completion_run_3":
            return "MOMENTUM"
        case "completion_run_7":
            return "UNSTOPPABLE"
        default:
            return definition.tier.displayName.uppercased()
        }
    }

    private var sparkleOffsets: [CGSize] {
        [
            CGSize(width: -size * 0.24, height: -size * 0.2),
            CGSize(width: size * 0.26, height: -size * 0.15),
            CGSize(width: -size * 0.21, height: size * 0.12),
            CGSize(width: size * 0.22, height: size * 0.16),
            CGSize(width: 0, height: -size * 0.3),
            CGSize(width: 0, height: size * 0.24)
        ]
    }

    var body: some View {
        ZStack {
            ribbonBackLayer
            badgeFrame
            ribbonHugShadow
            ribbonFrontLayer
        }
        .frame(width: size, height: size * 1.12)
        .shadow(
            color: palette.glow.opacity(isUnlocked ? 0.45 * glowBoost : 0.28),
            radius: isUnlocked ? 21 : 13,
            y: isUnlocked ? 12 : 7
        )
    }

    private var badgeFrame: some View {
        ZStack {
            AchievementHexagonShape()
                .fill(
                    LinearGradient(
                        colors: [palette.outerA, palette.outerB, palette.outerC],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            AchievementHexagonShape()
                .fill(
                    AngularGradient(
                        colors: [
                            palette.spectrumA.opacity(0.62),
                            palette.spectrumB.opacity(0.56),
                            palette.spectrumC.opacity(0.62),
                            palette.spectrumA.opacity(0.62)
                        ],
                        center: .center,
                        startAngle: .degrees(-18),
                        endAngle: .degrees(342)
                    )
                )
                .padding(size * 0.03)
                .opacity(isUnlocked ? 1 : 0.9)

            AchievementHexagonShape()
                .fill(
                    LinearGradient(
                        colors: [palette.innerA, palette.innerB, palette.innerC],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(size * 0.08)

            motifLayer
                .clipShape(AchievementHexagonShape())

            sparkleLayer

            centerMedallion

            if !isUnlocked {
                AchievementHexagonShape()
                    .fill(.black.opacity(0.22))

                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.9))
            }

            AchievementHexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isUnlocked ? 0.74 : 0.42),
                            Color.white.opacity(isUnlocked ? 0.2 : 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )

            AchievementHexagonShape()
                .stroke(Color.white.opacity(isUnlocked ? 0.2 : 0.12), lineWidth: 1)
                .padding(size * 0.12)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var motifLayer: some View {
        switch motif {
        case .rings:
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    let inset = size * (0.16 + (CGFloat(index) * 0.08))
                    let alpha = max(0.08, 0.28 - (Double(index) * 0.06))
                    AchievementHexagonShape()
                        .stroke(Color.white.opacity(isUnlocked ? alpha : alpha * 0.82), lineWidth: 1)
                        .padding(inset)
                }
            }
        case .rays:
            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [palette.spectrumA.opacity(0.72), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.03, height: size * 0.24)
                        .offset(y: -size * 0.15)
                        .rotationEffect(.degrees(Double(index) * 30))
                        .opacity(isUnlocked ? 0.88 : 0.72)
                }
            }
        case .stripes:
            ZStack {
                ForEach(-3...3, id: \.self) { index in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [palette.spectrumB.opacity(0.44), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.12, height: size * 1.1)
                        .offset(x: CGFloat(index) * size * 0.13)
                        .rotationEffect(.degrees(28))
                        .opacity(isUnlocked ? 0.9 : 0.72)
                }
            }
        case .constellation:
            ZStack {
                ForEach(Array(sparkleOffsets.enumerated()), id: \.offset) { index, offset in
                    Circle()
                        .fill(index.isMultiple(of: 2) ? palette.spectrumA.opacity(0.62) : palette.spectrumC.opacity(0.62))
                        .frame(
                            width: index.isMultiple(of: 2) ? size * 0.055 : size * 0.04,
                            height: index.isMultiple(of: 2) ? size * 0.055 : size * 0.04
                        )
                        .offset(offset)
                        .blur(radius: isUnlocked ? 0.5 : 0.2)
                        .opacity(isUnlocked ? 1 : 0.78)
                }
            }
        }
    }

    private var centerMedallion: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isUnlocked ? 0.36 : 0.28),
                            Color.white.opacity(isUnlocked ? 0.12 : 0.08)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: size * 0.24
                    )
                )
                .frame(width: size * 0.44, height: size * 0.44)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isUnlocked ? 0.58 : 0.36), lineWidth: 1)
                )

            Image(systemName: definition.icon)
                .font(.system(size: size * 0.22, weight: .black))
                .foregroundStyle(Color.white.opacity(isUnlocked ? 0.98 : 0.86))
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        }
    }

    private var sparkleLayer: some View {
        ZStack {
            ForEach(Array(sparkleOffsets.enumerated()), id: \.offset) { index, offset in
                Circle()
                    .fill(Color.white.opacity(isUnlocked ? 0.66 : 0.5))
                    .frame(
                        width: index.isMultiple(of: 2) ? 4.5 : 3.3,
                        height: index.isMultiple(of: 2) ? 4.5 : 3.3
                    )
                    .offset(offset)
            }
        }
    }

    private var ribbonBackLayer: some View {
        HStack(spacing: 0) {
            AchievementRibbonTailShape()
                .fill(
                    LinearGradient(
                        colors: [palette.tailA, palette.tailB],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.3, height: size * 0.2)

            Spacer(minLength: 0)

            AchievementRibbonTailShape()
                .fill(
                    LinearGradient(
                        colors: [palette.tailA, palette.tailB],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.3, height: size * 0.2)
                .scaleEffect(x: -1, y: 1)
        }
        .frame(width: size * 1.1, height: size * 0.22)
        .offset(y: size * 0.24)
        .shadow(color: .black.opacity(0.24), radius: 4, y: 2)
        .opacity(isUnlocked ? 1 : 0.93)
    }

    private var ribbonHugShadow: some View {
        AchievementRibbonBandShape()
            .fill(
                LinearGradient(
                    colors: [.black.opacity(0.28), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: size * 0.8, height: size * 0.11)
            .offset(y: size * 0.165)
            .opacity(isUnlocked ? 0.82 : 0.58)
    }

    private var ribbonFrontLayer: some View {
        ZStack {
            AchievementRibbonBandShape()
                .fill(
                    LinearGradient(
                        colors: [palette.ribbonA, palette.ribbonB, palette.ribbonA.opacity(0.97)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    AchievementRibbonBandShape()
                        .stroke(Color.white.opacity(isUnlocked ? 0.48 : 0.36), lineWidth: 1)
                )
                .overlay(
                    HStack(spacing: 0) {
                        AchievementRibbonFoldShape()
                            .fill(Color.black.opacity(0.22))
                            .frame(width: size * 0.07, height: size * 0.16)

                        Spacer(minLength: 0)

                        AchievementRibbonFoldShape()
                            .fill(Color.black.opacity(0.22))
                            .frame(width: size * 0.07, height: size * 0.16)
                            .scaleEffect(x: -1, y: 1)
                    }
                    .padding(.horizontal, size * 0.012)
                )
                .overlay(
                    AchievementRibbonBandShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(1)
                        .opacity(isUnlocked ? 1 : 0.9)
                )

            Text(ribbonLabel)
                .font(.system(size: max(size * 0.082, 8), weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(isUnlocked ? 0.98 : 0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .padding(.horizontal, size * 0.06)
        }
        .frame(width: size * 0.86, height: size * 0.2)
        .offset(y: size * 0.24)
        .shadow(color: .black.opacity(0.34), radius: 9, y: 4)
    }
}

private struct AchievementRibbonBandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.width * 0.07, y: rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.width * 0.93, y: rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width * 0.93, y: rect.height * 0.9))
        path.addLine(to: CGPoint(x: rect.width * 0.07, y: rect.height * 0.9))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.5))
        path.closeSubpath()

        return path
    }
}

private struct AchievementRibbonTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.maxX, y: rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.width * 0.28, y: rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.36))
        path.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.64))
        path.addLine(to: CGPoint(x: rect.width * 0.28, y: rect.height * 0.82))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.82))
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.5))
        path.closeSubpath()

        return path
    }
}

private struct AchievementRibbonFoldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.45, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.72))
        path.closeSubpath()

        return path
    }
}

private struct AchievementShowcaseOverlay: View {
    let definition: AchievementDefinition
    let unlocked: Achievement?
    let onDismiss: () -> Void

    @State private var accumulatedRotation = CGSize.zero
    @State private var dragRotation = CGSize.zero

    private var isUnlocked: Bool {
        unlocked != nil
    }

    private var xRotation: Double {
        Double(accumulatedRotation.height + dragRotation.height)
    }

    private var yRotation: Double {
        Double(accumulatedRotation.width + dragRotation.width)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.63)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: DeferTheme.spacing(1.25)) {
                HStack {
                    Text("Badge Showcase")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(DeferTheme.textMuted.opacity(0.76))

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.white.opacity(0.86))
                    }
                    .buttonStyle(.plain)
                }

                AchievementBadgeArtwork(
                    definition: definition,
                    isUnlocked: isUnlocked,
                    size: 240,
                    glowBoost: 1.3
                )
                .rotation3DEffect(
                    .degrees(xRotation),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.58
                )
                .rotation3DEffect(
                    .degrees(yRotation),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.58
                )
                .gesture(rotationGesture)
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        accumulatedRotation = .zero
                        dragRotation = .zero
                    }
                }
                .padding(.top, DeferTheme.spacing(0.5))
                .padding(.bottom, DeferTheme.spacing(1))

                Text(definition.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .multilineTextAlignment(.center)

                if let unlocked {
                    Text("Unlocked \(unlocked.unlockedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DeferTheme.success)
                } else {
                    Text("Locked preview")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DeferTheme.warning)
                }

                Text("Drag to rotate. Double-tap to reset orientation.")
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(DeferTheme.spacing(2))
            .frame(maxWidth: 380)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.36), radius: 28, y: 14)
            .padding(.horizontal, DeferTheme.spacing(2))
        }
    }

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragRotation = CGSize(
                    width: value.translation.width / 6.5,
                    height: -value.translation.height / 6.5
                )
            }
            .onEnded { value in
                let width = (accumulatedRotation.width + (value.translation.width / 6.5)).clamped(to: -45...45)
                let height = (accumulatedRotation.height - (value.translation.height / 6.5)).clamped(to: -45...45)

                withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                    accumulatedRotation = CGSize(width: width, height: height)
                    dragRotation = .zero
                }
            }
    }
}

private struct AchievementBadgePalette {
    let outerA: Color
    let outerB: Color
    let outerC: Color

    let innerA: Color
    let innerB: Color
    let innerC: Color

    let spectrumA: Color
    let spectrumB: Color
    let spectrumC: Color

    let ribbonA: Color
    let ribbonB: Color

    let tailA: Color
    let tailB: Color

    let glow: Color

    static func forKey(_ key: String, tier: AchievementTier) -> AchievementBadgePalette {
        switch key {
        case "first_completion":
            return AchievementBadgePalette(
                outerA: Color(red: 0.07, green: 0.84, blue: 0.83),
                outerB: Color(red: 0.06, green: 0.67, blue: 0.94),
                outerC: Color(red: 0.38, green: 0.35, blue: 1.0),
                innerA: Color(red: 0.59, green: 0.99, blue: 0.96),
                innerB: Color(red: 0.28, green: 0.93, blue: 0.89),
                innerC: Color(red: 0.11, green: 0.76, blue: 0.93),
                spectrumA: Color(red: 0.38, green: 1.0, blue: 0.90),
                spectrumB: Color(red: 0.57, green: 0.85, blue: 1.0),
                spectrumC: Color(red: 0.86, green: 0.63, blue: 1.0),
                ribbonA: Color(red: 0.10, green: 0.77, blue: 0.49),
                ribbonB: Color(red: 0.07, green: 0.58, blue: 0.33),
                tailA: Color(red: 0.08, green: 0.57, blue: 0.33),
                tailB: Color(red: 0.07, green: 0.45, blue: 0.27),
                glow: Color(red: 0.35, green: 1.0, blue: 0.86)
            )
        case "streak_7":
            return AchievementBadgePalette(
                outerA: Color(red: 0.05, green: 0.86, blue: 0.67),
                outerB: Color(red: 0.07, green: 0.70, blue: 0.52),
                outerC: Color(red: 0.30, green: 0.43, blue: 0.95),
                innerA: Color(red: 0.64, green: 0.99, blue: 0.79),
                innerB: Color(red: 0.29, green: 0.93, blue: 0.63),
                innerC: Color(red: 0.12, green: 0.76, blue: 0.47),
                spectrumA: Color(red: 0.55, green: 1.0, blue: 0.74),
                spectrumB: Color(red: 0.91, green: 0.95, blue: 0.48),
                spectrumC: Color(red: 0.38, green: 0.82, blue: 1.0),
                ribbonA: Color(red: 0.18, green: 0.76, blue: 0.40),
                ribbonB: Color(red: 0.11, green: 0.57, blue: 0.28),
                tailA: Color(red: 0.11, green: 0.55, blue: 0.28),
                tailB: Color(red: 0.09, green: 0.41, blue: 0.21),
                glow: Color(red: 0.56, green: 1.0, blue: 0.66)
            )
        case "streak_30":
            return AchievementBadgePalette(
                outerA: Color(red: 0.16, green: 0.67, blue: 1.0),
                outerB: Color(red: 0.22, green: 0.49, blue: 1.0),
                outerC: Color(red: 0.49, green: 0.34, blue: 1.0),
                innerA: Color(red: 0.64, green: 0.90, blue: 1.0),
                innerB: Color(red: 0.34, green: 0.73, blue: 1.0),
                innerC: Color(red: 0.23, green: 0.53, blue: 1.0),
                spectrumA: Color(red: 0.66, green: 0.93, blue: 1.0),
                spectrumB: Color(red: 0.75, green: 0.74, blue: 1.0),
                spectrumC: Color(red: 0.93, green: 0.56, blue: 1.0),
                ribbonA: Color(red: 0.37, green: 0.46, blue: 1.0),
                ribbonB: Color(red: 0.28, green: 0.33, blue: 0.95),
                tailA: Color(red: 0.24, green: 0.34, blue: 0.89),
                tailB: Color(red: 0.17, green: 0.25, blue: 0.70),
                glow: Color(red: 0.55, green: 0.80, blue: 1.0)
            )
        case "streak_100":
            return AchievementBadgePalette(
                outerA: Color(red: 0.79, green: 0.20, blue: 1.0),
                outerB: Color(red: 0.52, green: 0.24, blue: 1.0),
                outerC: Color(red: 0.20, green: 0.54, blue: 1.0),
                innerA: Color(red: 0.99, green: 0.51, blue: 1.0),
                innerB: Color(red: 0.80, green: 0.30, blue: 0.99),
                innerC: Color(red: 0.42, green: 0.34, blue: 1.0),
                spectrumA: Color(red: 1.0, green: 0.62, blue: 0.97),
                spectrumB: Color(red: 0.75, green: 0.66, blue: 1.0),
                spectrumC: Color(red: 0.37, green: 0.90, blue: 1.0),
                ribbonA: Color(red: 0.74, green: 0.29, blue: 1.0),
                ribbonB: Color(red: 0.55, green: 0.23, blue: 0.92),
                tailA: Color(red: 0.50, green: 0.20, blue: 0.84),
                tailB: Color(red: 0.37, green: 0.16, blue: 0.65),
                glow: Color(red: 0.88, green: 0.44, blue: 1.0)
            )
        case "category_mastery_3":
            return AchievementBadgePalette(
                outerA: Color(red: 1.0, green: 0.59, blue: 0.21),
                outerB: Color(red: 1.0, green: 0.46, blue: 0.33),
                outerC: Color(red: 0.96, green: 0.76, blue: 0.23),
                innerA: Color(red: 1.0, green: 0.92, blue: 0.62),
                innerB: Color(red: 1.0, green: 0.79, blue: 0.30),
                innerC: Color(red: 0.99, green: 0.61, blue: 0.26),
                spectrumA: Color(red: 1.0, green: 0.92, blue: 0.56),
                spectrumB: Color(red: 1.0, green: 0.70, blue: 0.36),
                spectrumC: Color(red: 1.0, green: 0.50, blue: 0.33),
                ribbonA: Color(red: 0.98, green: 0.41, blue: 0.30),
                ribbonB: Color(red: 0.88, green: 0.28, blue: 0.22),
                tailA: Color(red: 0.81, green: 0.26, blue: 0.20),
                tailB: Color(red: 0.61, green: 0.20, blue: 0.17),
                glow: Color(red: 1.0, green: 0.74, blue: 0.35)
            )
        case "category_mastery_10":
            return AchievementBadgePalette(
                outerA: Color(red: 1.0, green: 0.77, blue: 0.22),
                outerB: Color(red: 0.96, green: 0.60, blue: 0.16),
                outerC: Color(red: 0.89, green: 0.36, blue: 0.21),
                innerA: Color(red: 1.0, green: 0.94, blue: 0.58),
                innerB: Color(red: 1.0, green: 0.80, blue: 0.29),
                innerC: Color(red: 0.97, green: 0.60, blue: 0.26),
                spectrumA: Color(red: 1.0, green: 0.96, blue: 0.62),
                spectrumB: Color(red: 1.0, green: 0.68, blue: 0.33),
                spectrumC: Color(red: 1.0, green: 0.45, blue: 0.29),
                ribbonA: Color(red: 0.97, green: 0.34, blue: 0.26),
                ribbonB: Color(red: 0.84, green: 0.24, blue: 0.21),
                tailA: Color(red: 0.76, green: 0.22, blue: 0.18),
                tailB: Color(red: 0.56, green: 0.16, blue: 0.15),
                glow: Color(red: 1.0, green: 0.73, blue: 0.30)
            )
        case "completion_run_3":
            return AchievementBadgePalette(
                outerA: Color(red: 0.69, green: 0.95, blue: 0.17),
                outerB: Color(red: 0.37, green: 0.84, blue: 0.24),
                outerC: Color(red: 0.98, green: 0.68, blue: 0.14),
                innerA: Color(red: 0.90, green: 0.99, blue: 0.58),
                innerB: Color(red: 0.59, green: 0.96, blue: 0.40),
                innerC: Color(red: 0.98, green: 0.80, blue: 0.25),
                spectrumA: Color(red: 0.92, green: 1.0, blue: 0.52),
                spectrumB: Color(red: 0.62, green: 0.98, blue: 0.48),
                spectrumC: Color(red: 1.0, green: 0.76, blue: 0.30),
                ribbonA: Color(red: 0.35, green: 0.77, blue: 0.28),
                ribbonB: Color(red: 0.25, green: 0.61, blue: 0.21),
                tailA: Color(red: 0.23, green: 0.53, blue: 0.18),
                tailB: Color(red: 0.18, green: 0.40, blue: 0.15),
                glow: Color(red: 0.71, green: 0.99, blue: 0.41)
            )
        case "completion_run_7":
            return AchievementBadgePalette(
                outerA: Color(red: 1.0, green: 0.33, blue: 0.72),
                outerB: Color(red: 0.94, green: 0.26, blue: 0.42),
                outerC: Color(red: 0.70, green: 0.20, blue: 0.94),
                innerA: Color(red: 1.0, green: 0.58, blue: 0.86),
                innerB: Color(red: 0.99, green: 0.40, blue: 0.56),
                innerC: Color(red: 0.83, green: 0.28, blue: 0.98),
                spectrumA: Color(red: 1.0, green: 0.68, blue: 0.85),
                spectrumB: Color(red: 1.0, green: 0.56, blue: 0.45),
                spectrumC: Color(red: 0.78, green: 0.52, blue: 1.0),
                ribbonA: Color(red: 0.87, green: 0.27, blue: 0.90),
                ribbonB: Color(red: 0.65, green: 0.21, blue: 0.78),
                tailA: Color(red: 0.59, green: 0.18, blue: 0.69),
                tailB: Color(red: 0.42, green: 0.13, blue: 0.50),
                glow: Color(red: 0.99, green: 0.43, blue: 0.85)
            )
        default:
            return forTierFallback(tier)
        }
    }

    private static func forTierFallback(_ tier: AchievementTier) -> AchievementBadgePalette {
        switch tier {
        case .bronze:
            return AchievementBadgePalette(
                outerA: Color(red: 0.69, green: 0.50, blue: 0.29),
                outerB: Color(red: 0.53, green: 0.37, blue: 0.23),
                outerC: Color(red: 0.79, green: 0.61, blue: 0.36),
                innerA: Color(red: 0.90, green: 0.77, blue: 0.55),
                innerB: Color(red: 0.78, green: 0.61, blue: 0.36),
                innerC: Color(red: 0.60, green: 0.44, blue: 0.27),
                spectrumA: Color(red: 0.95, green: 0.79, blue: 0.49),
                spectrumB: Color(red: 0.80, green: 0.60, blue: 0.33),
                spectrumC: Color(red: 0.59, green: 0.42, blue: 0.25),
                ribbonA: Color(red: 0.66, green: 0.44, blue: 0.25),
                ribbonB: Color(red: 0.50, green: 0.33, blue: 0.20),
                tailA: Color(red: 0.45, green: 0.29, blue: 0.17),
                tailB: Color(red: 0.34, green: 0.22, blue: 0.14),
                glow: Color(red: 0.90, green: 0.70, blue: 0.39)
            )
        case .silver:
            return AchievementBadgePalette(
                outerA: Color(red: 0.71, green: 0.77, blue: 0.83),
                outerB: Color(red: 0.55, green: 0.63, blue: 0.71),
                outerC: Color(red: 0.79, green: 0.86, blue: 0.91),
                innerA: Color(red: 0.92, green: 0.96, blue: 0.99),
                innerB: Color(red: 0.76, green: 0.84, blue: 0.91),
                innerC: Color(red: 0.60, green: 0.69, blue: 0.77),
                spectrumA: Color(red: 0.96, green: 0.98, blue: 1.0),
                spectrumB: Color(red: 0.77, green: 0.84, blue: 0.91),
                spectrumC: Color(red: 0.59, green: 0.68, blue: 0.76),
                ribbonA: Color(red: 0.58, green: 0.67, blue: 0.76),
                ribbonB: Color(red: 0.48, green: 0.56, blue: 0.64),
                tailA: Color(red: 0.43, green: 0.50, blue: 0.57),
                tailB: Color(red: 0.35, green: 0.41, blue: 0.47),
                glow: Color(red: 0.84, green: 0.90, blue: 0.96)
            )
        case .gold:
            return AchievementBadgePalette(
                outerA: Color(red: 1.0, green: 0.81, blue: 0.24),
                outerB: Color(red: 0.97, green: 0.63, blue: 0.16),
                outerC: Color(red: 0.90, green: 0.42, blue: 0.14),
                innerA: Color(red: 1.0, green: 0.95, blue: 0.62),
                innerB: Color(red: 1.0, green: 0.79, blue: 0.29),
                innerC: Color(red: 0.96, green: 0.58, blue: 0.22),
                spectrumA: Color(red: 1.0, green: 0.96, blue: 0.62),
                spectrumB: Color(red: 1.0, green: 0.75, blue: 0.30),
                spectrumC: Color(red: 1.0, green: 0.49, blue: 0.23),
                ribbonA: Color(red: 0.96, green: 0.40, blue: 0.21),
                ribbonB: Color(red: 0.82, green: 0.26, blue: 0.17),
                tailA: Color(red: 0.74, green: 0.21, blue: 0.15),
                tailB: Color(red: 0.52, green: 0.16, blue: 0.11),
                glow: Color(red: 1.0, green: 0.76, blue: 0.31)
            )
        case .legend:
            return AchievementBadgePalette(
                outerA: Color(red: 0.79, green: 0.23, blue: 1.0),
                outerB: Color(red: 0.53, green: 0.22, blue: 0.98),
                outerC: Color(red: 0.25, green: 0.48, blue: 1.0),
                innerA: Color(red: 1.0, green: 0.49, blue: 1.0),
                innerB: Color(red: 0.80, green: 0.31, blue: 0.99),
                innerC: Color(red: 0.40, green: 0.33, blue: 0.99),
                spectrumA: Color(red: 1.0, green: 0.64, blue: 1.0),
                spectrumB: Color(red: 0.78, green: 0.52, blue: 1.0),
                spectrumC: Color(red: 0.37, green: 0.79, blue: 1.0),
                ribbonA: Color(red: 0.73, green: 0.26, blue: 0.99),
                ribbonB: Color(red: 0.55, green: 0.21, blue: 0.85),
                tailA: Color(red: 0.49, green: 0.18, blue: 0.76),
                tailB: Color(red: 0.35, green: 0.13, blue: 0.55),
                glow: Color(red: 0.84, green: 0.42, blue: 1.0)
            )
        }
    }
}

private struct AchievementHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.09

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.78))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.22))
        path.closeSubpath()

        return path
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension AchievementRule {
    func progressValue(using progress: AchievementProgress) -> (current: Int, target: Int) {
        switch self {
        case .minCompletions(let target):
            return (min(progress.completionCount, target), target)
        case .minStreak(let target):
            return (min(progress.maxStreak, target), target)
        case .categoryMastery(let target):
            return (min(progress.highestCategoryCompletionCount, target), target)
        case .consecutiveCompletions(let target):
            return (min(progress.maxConsecutiveCompletions, target), target)
        }
    }
}
