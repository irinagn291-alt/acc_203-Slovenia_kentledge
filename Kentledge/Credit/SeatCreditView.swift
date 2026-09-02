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
            Text("Put the money somewhere")
                .hullText(.title)
            if let pending = plate.pendingLoad {
                Text(HullFigures.money(pending, code: plate.currencyCode))
                    .hullText(.load)
                Text("Tap another charge you keep, or a savings name. The cancel finishes only when this money lands.")
                    .hullText(.body)
                KeepRail(keeps: plate.keeps, pending: true) { id in
                    Task { await watch.seat(on: .keep(id)) }
                }
                SinkRail(sinks: plate.sinks, pending: true, onSeat: { id in
                    Task { await watch.seat(on: .sink(id)) }
                }, onAdd: onAddSink)
                HullChromeButton(title: "Undo cancel") {
                    Task { await watch.abandon() }
                }
            } else if watch.fault != nil {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "Could not place the money.",
                    line: watch.fault ?? "Try again.",
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await watch.retry() }
                }
            } else {
                HullVacancy(
                    image: "ktl_TwistHero",
                    headline: "Nothing is free yet",
                    line: "Cancel a charge on the home list. The monthly amount must land somewhere before the total drops.",
                    actionTitle: "Back to charges"
                ) {}
            }
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HullSwatch.background.ignoresSafeArea())
    }
}
