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
                        title: "See this month’s bill",
                        line: "Name each charge and when it hits. The total is only for months that actually bill — not a smeared year."
                    )
                case 1:
                    pageView(
                        image: "ktl_Onboarding2",
                        title: "Cancel has a cost of honesty",
                        line: "Tap a charge to cancel it. The monthly amount becomes free money you must place somewhere."
                    )
                case 2:
                    pageView(
                        image: "ktl_Onboarding3",
                        title: "Put the money somewhere",
                        line: "Keep another charge, or name a savings bucket. Only then the monthly total drops."
                    )
                default:
                    pageView(
                        image: "ktl_TwistHero",
                        title: "Saved by cutting",
                        line: "Money you placed after a cancel is your savings. What if I cut… ranks what you still pay."
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
                Text(page < 3 ? "Next" : "Show my charges")
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
