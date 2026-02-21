import SwiftUI

struct AchievementShowcaseOverlay: View {
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

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    let definition = AchievementCatalog.all.first ?? AchievementDefinition(
        key: "first_intentional_choice",
        title: "First Intentional Choice",
        details: "Resolve one intent with a deliberate outcome.",
        tier: .bronze,
        icon: "sparkles",
        rule: .minIntentionalDecisions(1)
    )

    let item = PreviewFixtures.sampleDefer(
        title: "Sample",
        details: "Preview source item",
        category: .habit,
        status: .completed,
        strictMode: false,
        streakCount: 5,
        startDate: Calendar.current.date(byAdding: .day, value: -8, to: .now) ?? .now,
        targetDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    )

    let unlocked = PreviewFixtures.sampleAchievement(
        key: definition.key,
        sourceDefer: item
    )

    return AchievementShowcaseOverlay(
        definition: definition,
        unlocked: unlocked,
        onDismiss: {}
    )
}
