import SwiftUI

/// Role: Beam. Ballast sheet. Currency, reminder, contact, reset. ReviewScreen goals.
struct SettingsView: View {
    @ObservedObject var watch: BeamWatch
    var onClose: () -> Void
    var onRerun: () -> Void

    @State private var currency: String
    @State private var reminderEnabled: Bool
    @State private var reminderHour: Int
    @State private var confirmReset = false
    @State private var sinkName = ""

    init(
        watch: BeamWatch,
        onClose: @escaping () -> Void = {},
        onRerun: @escaping () -> Void = {}
    ) {
        self.watch = watch
        self.onClose = onClose
        self.onRerun = onRerun
        _currency = State(initialValue: watch.beam.ballast.currencyCode)
        _reminderEnabled = State(initialValue: watch.beam.ballast.reminderEnabled)
        _reminderHour = State(initialValue: watch.beam.ballast.reminderHour)
    }

    init() {
        self.init(watch: .previewPopulated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
            HullSheetBar(title: "Settings", onClose: onClose)
            if watch.warning == .startedEmpty, watch.beam.bricks.isEmpty {
                HullVacancy(
                    image: "ktl_EmptyList",
                    headline: "Ballast was lost.",
                    line: "The ledger started empty. Currency and reminder can still be set.",
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await watch.retry() }
                }
            } else if let fault = watch.fault {
                errorBlock(fault)
            } else {
                populated
            }
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(HullSwatch.background.ignoresSafeArea())
        .confirmationDialog("Reset the whole beam?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await watch.resetAll() }
            }
            Button("Hold", role: .cancel) {}
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
                Text("Ballast")
                    .hullText(.stencil)
                TextField("Currency", text: $currency)
                    .hullText(.body)
                    .textInputAutocapitalization(.characters)
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                    .onChange(of: currency, initial: false) { _, next in
                        currency = String(next.uppercased().prefix(3))
                    }
                Toggle(isOn: $reminderEnabled) {
                    Text("Local reminder")
                        .hullText(.body)
                }
                .frame(minHeight: HullSwatch.tap)
                .tint(HullSwatch.accent)
                if reminderEnabled {
                    Stepper(value: $reminderHour, in: 0 ... 23) {
                        Text("Hour \(HullFigures.hour(reminderHour))")
                            .hullText(.body)
                    }
                    .frame(minHeight: HullSwatch.tap)
                }
                HullChromeButton(title: "Write ballast", fillsWidth: true) {
                    Task { await persistBallast() }
                }
                Text("Sinks")
                    .hullText(.stencil)
                TextField("Sink name", text: $sinkName)
                    .hullText(.body)
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                HullChromeButton(title: "Name sink", fillsWidth: true) {
                    let name = sinkName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    Task {
                        await watch.saveSink(NamedSink(name: name))
                        sinkName = ""
                    }
                }
                Link(destination: BeamClient.contactURL) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Contact Kentledge")
                            .hullText(.body)
                            .foregroundStyle(HullSwatch.accent)
                        Text(BeamClient.contactURL.absoluteString)
                            .hullText(.caption)
                            .foregroundStyle(HullSwatch.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, HullSwatch.space(1))
                    .frame(minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                HullChromeButton(title: "Re-run onboarding", fillsWidth: true, action: onRerun)
                Button {
                    confirmReset = true
                } label: {
                    Text("Reset all data")
                        .hullText(.body)
                        .foregroundStyle(HullSwatch.accent)
                        .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                        .background(HullSwatch.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .contentMargins(.bottom, HullSwatch.space(2))
    }

    private func errorBlock(_ fault: String) -> some View {
        HullVacancy(
            image: "ktl_EmptyList",
            headline: "Settings could not write.",
            line: fault,
            actionTitle: "Retry",
            retry: true
        ) {
            Task { await persistBallast() }
        }
    }

    private func persistBallast() async {
        var ballast = watch.beam.ballast
        let code = currency.trimmingCharacters(in: .whitespacesAndNewlines)
        ballast.currencyCode = code.count == 3 ? code : ballast.currencyCode
        ballast.reminderEnabled = reminderEnabled
        ballast.reminderHour = reminderHour
        await watch.saveBallast(ballast)
    }
}
