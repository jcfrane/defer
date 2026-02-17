import SwiftUI

struct AppPageHeaderView<Subtitle: View, Trailing: View>: View {
    let title: String
    @ViewBuilder private let subtitle: () -> Subtitle
    @ViewBuilder private let trailing: () -> Trailing

    init(
        title: String,
        @ViewBuilder subtitle: @escaping () -> Subtitle,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DeferTheme.spacing(1.25)) {
            HStack(alignment: .center, spacing: DeferTheme.spacing(1.5)) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(DeferTheme.textPrimary)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                Spacer(minLength: 0)

                trailing()
            }

            subtitle()
        }
    }
}

extension AppPageHeaderView where Subtitle == EmptyView {
    init(
        title: String,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.init(title: title, subtitle: { EmptyView() }, trailing: trailing)
    }
}

extension AppPageHeaderView where Trailing == EmptyView {
    init(
        title: String,
        @ViewBuilder subtitle: @escaping () -> Subtitle
    ) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() })
    }
}

extension AppPageHeaderView where Subtitle == EmptyView, Trailing == EmptyView {
    init(title: String) {
        self.init(title: title, subtitle: { EmptyView() }, trailing: { EmptyView() })
    }
}

#Preview {
    ZStack {
        DeferTheme.homeBackground
            .ignoresSafeArea()

        AppPageHeaderView(
            title: "Morning",
            subtitle: {
                Text("Move one step with intention today.")
                    .font(.caption)
                    .foregroundStyle(DeferTheme.textMuted)
            },
            trailing: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(DeferTheme.textPrimary)
            }
        )
        .padding()
    }
}
