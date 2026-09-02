import SwiftUI

/// Role: Credit. History of seated cuts — what canceling actually funded.
struct CutsView: View {
    @ObservedObject var watch: BeamWatch
    var onClose: () -> Void
    @State private var showShare = false

    init(watch: BeamWatch, onClose: @escaping () -> Void = {}) {
        self.watch = watch
        self.onClose = onClose
    }

    init() {
        self.init(watch: .previewPopulated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
            HullSheetBar(title: "Cuts", onClose: onClose)
            if cuts.isEmpty {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "No cuts yet",
                    line: "Cancel a charge and put the money somewhere. Each seated cut lands here.",
                    actionTitle: "Close"
                ) {
                    onClose()
                }
            } else {
                summary
                list
            }
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HullSwatch.background.ignoresSafeArea())
        .sheet(isPresented: $showShare) {
            HullShareSheet(text: shareText)
        }
    }

    private var cuts: [SeatCredit] {
        watch.beam.seatedCredits.reversed()
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved / month")
                        .hullText(.stencil)
                    Text(HullFigures.money(watch.beam.cancelSavings, code: code))
                        .hullText(.title)
                        .monospacedDigit()
                }
                Spacer(minLength: HullSwatch.space(1))
                VStack(alignment: .trailing, spacing: 2) {
                    Text("About / year")
                        .hullText(.stencil)
                    Text(HullFigures.money(watch.beam.cancelSavingsYear, code: code))
                        .hullText(.title)
                        .monospacedDigit()
                }
            }
            HullChromeButton(title: "Share cuts summary", fillsWidth: true) {
                showShare = true
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
                Text("Seated cuts")
                    .hullText(.stencil)
                ForEach(cuts) { cut in
                    HStack(alignment: .firstTextBaseline, spacing: HullSwatch.space(1)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cut.title)
                                .font(HullStep.body.font)
                                .foregroundStyle(HullSwatch.ink)
                                .lineLimit(1)
                            Text(berthLine(cut))
                                .font(HullStep.caption.font)
                                .foregroundStyle(HullSwatch.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: HullSwatch.space(1))
                        Text(HullFigures.money(cut.monthlyEquivalent, code: code))
                            .font(HullStep.body.font.monospacedDigit())
                            .foregroundStyle(HullSwatch.ink)
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap, alignment: .leading)
                    .background(HullSwatch.surface)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

    private func berthLine(_ cut: SeatCredit) -> String {
        guard let berth = cut.berth else { return "Unplaced" }
        switch berth {
        case .keep(let id):
            let name = watch.beam.bricks.first(where: { $0.id == id })?.name ?? "another charge"
            return "Kept \(name)"
        case .sink(let id):
            let name = watch.beam.sinks.first(where: { $0.id == id })?.name ?? "savings"
            return "Put in \(name)"
        }
    }
}
