import SwiftUI

/// Role: Brick. Sheet ranking uncut posts by what they would free. ReviewScreen log.
struct InsightsView: View {
    @ObservedObject var watch: BeamWatch
    var onClose: () -> Void
    var onAdd: () -> Void
    @State private var showShare = false

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
            HullSheetBar(title: "What if I cut…", onClose: onClose)
            if let fault = watch.fault {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "Could not load this list.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await watch.retry() }
                }
            } else if ranked.isEmpty {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "No charges to cut",
                    line: "Add a named charge first. Then you will see how much canceling each one would free.",
                    actionTitle: "Add a charge"
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
        .sheet(isPresented: $showShare) {
            HullShareSheet(text: shareText)
        }
    }

    private var ranked: [ChargeBrick] {
        watch.beam.uncutRankedByFreeing()
    }

    private var code: String {
        watch.beam.ballast.currencyCode
    }

    private var shareText: String {
        BeamMath.shareSummary(
            monthLoad: watch.beam.monthlyLoad,
            yearLoad: watch.beam.yearlyLoad,
            savedMonth: watch.beam.cancelSavings,
            chargeCount: watch.beam.bricks.count,
            cutCount: watch.beam.seatedCredits.count,
            currencyCode: code
        )
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
                totals
                BeamChartPanel(
                    posts: watch.plate.posts.filter { !$0.ghosted },
                    monthLoad: watch.beam.monthlyLoad,
                    saved: watch.beam.cancelSavings,
                    currencyCode: code
                )
                upcoming
                Text("What canceling would free each month")
                    .font(HullStep.caption.font.weight(.semibold))
                    .foregroundStyle(HullSwatch.muted)
                    .textCase(.uppercase)
                    .tracking(0.6)
                ForEach(ranked) { brick in
                    HStack(alignment: .firstTextBaseline, spacing: HullSwatch.space(1)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(brick.name)
                                .font(HullStep.body.font)
                                .foregroundStyle(HullSwatch.ink)
                                .lineLimit(1)
                            Text(BeamMath.periodLine(period: brick.period, nextChargeDay: brick.nextChargeDay))
                                .font(HullStep.caption.font)
                                .foregroundStyle(HullSwatch.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: HullSwatch.space(1))
                        Text(HullFigures.money(brick.monthlyEquivalent, code: code))
                            .font(HullStep.body.font.monospacedDigit())
                            .foregroundStyle(HullSwatch.ink)
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap, alignment: .leading)
                    .background(HullSwatch.surface)
                }
                HullChromeButton(title: "Share this month", fillsWidth: true) {
                    showShare = true
                }
            }
        }
        .contentMargins(.bottom, HullSwatch.space(2))
    }

    private var totals: some View {
        HStack(alignment: .firstTextBaseline, spacing: HullSwatch.space(1)) {
            VStack(alignment: .leading, spacing: 2) {
                Text("This month")
                    .hullText(.stencil)
                Text(HullFigures.money(watch.beam.monthlyLoad, code: code))
                    .hullText(.title)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 2) {
                Text("About / year")
                    .hullText(.stencil)
                Text(HullFigures.money(watch.beam.yearlyLoad, code: code))
                    .hullText(.title)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(HullSwatch.space(2))
        .background(HullSwatch.surface)
    }

    private var upcoming: some View {
        let next = ranked.sorted { $0.nextChargeDay < $1.nextChargeDay }.prefix(3)
        return VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            Text("Next on the calendar")
                .hullText(.stencil)
            if next.isEmpty {
                Text("No upcoming charge dates.")
                    .font(HullStep.caption.font)
                    .foregroundStyle(HullSwatch.muted)
            } else {
                ForEach(Array(next)) { brick in
                    HStack {
                        Text(brick.name)
                            .font(HullStep.body.font)
                            .foregroundStyle(HullSwatch.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(HullFigures.day(brick.nextChargeDay))
                            .font(HullStep.caption.font)
                            .foregroundStyle(HullSwatch.muted)
                    }
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                }
            }
        }
    }
}
