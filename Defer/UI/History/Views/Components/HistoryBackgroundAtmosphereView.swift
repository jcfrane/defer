import SwiftUI

struct HistoryBackgroundAtmosphereView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DeferTheme.success.opacity(0.32), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 220
                        )
                    )
                    .frame(width: 320, height: 320)
                    .position(x: size.width * 0.16, y: size.height * 0.14)
                    .blur(radius: 26)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [DeferTheme.warning.opacity(0.24), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 260
                        )
                    )
                    .frame(width: 420, height: 420)
                    .position(x: size.width * 0.92, y: size.height * 0.26)
                    .blur(radius: 34)

                RoundedRectangle(cornerRadius: 200, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DeferTheme.surface.opacity(0.16), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size.width * 1.1, height: size.height * 0.72)
                    .rotationEffect(.degrees(-12))
                    .position(x: size.width * 0.5, y: size.height * 0.84)
                    .blur(radius: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        HistoryBackgroundAtmosphereView()
    }
}
