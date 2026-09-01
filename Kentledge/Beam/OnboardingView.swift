import SwiftUI

/// Role: Beam. Three-to-four pages. Skip still writes defaults. Re-runnable from Settings.
struct OnboardingView: View {
    var onFinish: (Bool) -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(onFinish: @escaping (Bool) -> Void = { _ in }) {
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: HullSwatch.space(2)) {
            Group {
                switch page {
                case 0:
                    pageView(
                        image: "ktl_Onboarding1",
                        title: "This month's load",
                        line: "The beam holds charge bricks for the month that actually bills. Nothing is smeared across the year."
                    )
                case 1:
                    pageView(
                        image: "ktl_Onboarding2",
                        title: "Jettison a brick",
                        line: "Drag a post off the beam. It ghosts. A credit equal to the monthly load appears."
                    )
                case 2:
                    pageView(
                        image: "ktl_Onboarding3",
                        title: "A cut must seat",
                        line: "Land the credit on a remaining keep or a named sink. Only then the load drops."
                    )
                default:
                    pageView(
                        image: "ktl_TwistHero",
                        title: "Cancel-savings on the beam",
                        line: "Seated credit is the savings. There is no canceled list. Insights ranks what is still standing."
                    )
                }
            }
            .frame(maxHeight: .infinity)
            .animation(reduceMotion ? nil : HullSwatch.motion, value: page)
            Button {
                if page < 3 {
                    page += 1
                } else {
                    onFinish(false)
                }
            } label: {
                Text(page < 3 ? "Next" : "Open the beam")
                    .hullText(.body)
                    .foregroundStyle(HullSwatch.ink)
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                    .background(HullSwatch.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                onFinish(true)
            } label: {
                Text("Skip")
                    .hullText(.body)
                    .foregroundStyle(HullSwatch.muted)
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HullSwatch.background.ignoresSafeArea())
    }

    private func pageView(image: String, title: String, line: String) -> some View {
        VStack(spacing: HullSwatch.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .accessibilityHidden(true)
            Text(title)
                .hullText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .hullText(.body)
                .foregroundStyle(HullSwatch.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
