import SwiftUI

/// Role: Credit. Twist screen. A cut is not committed until this credit seats.
struct SeatCreditView: View {
    @ObservedObject var watch: BeamWatch
    var onAddSink: () -> Void

    init(watch: BeamWatch, onAddSink: @escaping () -> Void = {}) {
        self.watch = watch
        self.onAddSink = onAddSink
    }

    init() {
        self.init(watch: .previewPending())
    }

    var body: some View {
        let plate = watch.plate
        VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
            Text("Seat the credit")
                .hullText(.title)
            if let pending = plate.pendingLoad {
                Text(HullFigures.money(pending, code: plate.currencyCode))
                    .hullText(.load)
                Text("Tap a keep or a named sink. The cut commits when this credit lands.")
                    .hullText(.body)
                KeepRail(keeps: plate.keeps, pending: true) { id in
                    Task { await watch.seat(on: .keep(id)) }
                }
                SinkRail(sinks: plate.sinks, pending: true, onSeat: { id in
                    Task { await watch.seat(on: .sink(id)) }
                }, onAdd: onAddSink)
                HullChromeButton(title: "Abandon") {
                    Task { await watch.abandon() }
                }
            } else if watch.fault != nil {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "The credit could not seat.",
                    line: watch.fault ?? "The beam refused the berth.",
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await watch.retry() }
                }
            } else {
                HullVacancy(
                    image: "ktl_TwistHero",
                    headline: "No credit is loose.",
                    line: "Drag a brick off the beam. The freed monthly load must seat before the cut commits.",
                    actionTitle: "Open the beam"
                ) {}
            }
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HullSwatch.background.ignoresSafeArea())
    }
}
