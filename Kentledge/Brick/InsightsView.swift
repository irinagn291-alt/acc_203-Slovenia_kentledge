import SwiftUI

/// Role: Brick. Sheet ranking uncut posts by what they would free. ReviewScreen log.
struct InsightsView: View {
    @ObservedObject var watch: BeamWatch
    var onClose: () -> Void
    var onAdd: () -> Void

    init(
        watch: BeamWatch,
        onClose: @escaping () -> Void = {},
        onAdd: @escaping () -> Void = {}
    ) {
        self.watch = watch
        self.onClose = onClose
        self.onAdd = onAdd
    }

    init() {
        self.init(watch: .previewPopulated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
            HullSheetBar(title: "Insights", onClose: onClose)
            if let fault = watch.fault {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "Insights could not load.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await watch.retry() }
                }
            } else if ranked.isEmpty {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "No uncut bricks.",
                    line: "Stand a brick on the beam to see what a cut would free.",
                    actionTitle: "Stand a brick"
                ) {
                    onClose()
                    onAdd()
                }
            } else {
                populated
            }
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HullSwatch.background.ignoresSafeArea())
    }

    private var ranked: [ChargeBrick] {
        watch.beam.uncutRankedByFreeing()
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
                Text("What a cut would free")
                    .hullText(.stencil)
                ForEach(ranked) { brick in
                    HStack(spacing: HullSwatch.space(1)) {
                        Text(brick.name)
                            .hullText(.body)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: HullSwatch.space(1))
                        Text(HullFigures.money(brick.monthlyEquivalent, code: watch.beam.ballast.currencyCode))
                            .hullText(.body)
                            .monospacedDigit()
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                }
            }
        }
        .contentMargins(.bottom, HullSwatch.space(2))
    }
}
