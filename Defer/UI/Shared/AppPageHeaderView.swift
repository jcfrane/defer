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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

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
