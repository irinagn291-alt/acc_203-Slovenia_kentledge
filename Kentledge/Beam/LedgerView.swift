import SwiftUI

/// Role: Beam. Root load beam. The home verb is seat-the-credit. ReviewScreen today.
struct LedgerView: View {
    @ObservedObject var watch: BeamWatch
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showInsights = false
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var showSinkName = false
    @State private var sinkName = ""
    @State private var dayStamp = Calendar.current.startOfDay(for: Date())
    @State private var showSuccess = false
    @State private var successTask: Task<Void, Never>?

    init(watch: BeamWatch, handlesLaunch: Bool = true) {
        self.watch = watch
        self.handlesLaunch = handlesLaunch
    }

    init() {
        self.init(watch: .previewPopulated(), handlesLaunch: false)
    }

    var body: some View {
        Group {
            if !watch.onboardingComplete && handlesLaunch {
                OnboardingView { skipped in
                    Task { await watch.finishOnboarding(skipped: skipped) }
                }
            } else {
                ledger
            }
        }
        .background(HullSwatch.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task {
            guard handlesLaunch else { return }
            await watch.appear()
            applyReview()
        }
        .onChange(of: scenePhase, initial: false) { _, phase in
            guard handlesLaunch else { return }
            if phase == .active {
                dayStamp = Calendar.current.startOfDay(for: Date())
            }
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            dayStamp = Calendar.current.startOfDay(for: Date())
        }
        .onDisappear {
            successTask?.cancel()
        }
        .sheet(isPresented: $showInsights) {
            InsightsView(
                watch: watch,
                onClose: { showInsights = false },
                onAdd: { watch.beginAdd() }
            )
            .presentationDetents([.large])
            .presentationBackground(HullSwatch.background)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                watch: watch,
                onClose: { showSettings = false },
                onRerun: {
                    showSettings = false
                    Task { await watch.reopenOnboarding() }
                }
            )
            .presentationDetents([.large])
            .presentationBackground(HullSwatch.background)
        }
        .alert("Name a sink", isPresented: $showSinkName) {
            TextField("Sink", text: $sinkName)
            Button("Stand") {
                let name = sinkName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    Task { await watch.saveSink(NamedSink(name: name)) }
                }
                sinkName = ""
            }
            Button("Hold", role: .cancel) { sinkName = "" }
        }
    }

    private var ledger: some View {
        VStack(spacing: 0) {
            header
            if watch.isHauling {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        ProgressView()
                            .tint(HullSwatch.accent)
                    }
            } else if let fault = watch.fault, watch.warning == .startedEmpty {
                HullVacancy(
                    image: "ktl_EmptyHome",
                    headline: "The beam could not be read.",
                    line: fault,
                    actionTitle: "Retry",
                    retry: true
                ) {
                    Task { await watch.retry() }
                }
            } else if watch.beam.bricks.isEmpty, watch.beam.seatedCredits.isEmpty, watch.beam.pendingCut == nil, !watch.isAdding, watch.expandingBrickID == nil {
                HullVacancy(
                    image: "ktl_EmptyHome",
                    headline: "No subscriptions yet.",
                    line: "Add one to see the monthly load.",
                    actionTitle: "Stand a brick"
                ) {
                    watch.beginAdd()
                }
            } else {
                populated
            }
        }
        .background(HullSwatch.background.ignoresSafeArea())
        .animation(reduceMotion ? nil : HullSwatch.motion, value: watch.beam.pendingCut?.id)
        .overlay {
            if showSuccess {
                Image("ktl_SuccessMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: HullSwatch.space(10), height: HullSwatch.space(10))
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? .linear(duration: 0.2) : HullSwatch.motion, value: showSuccess)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            HStack(alignment: .firstTextBaseline, spacing: HullSwatch.space(1)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Monthly load")
                        .hullText(.stencil)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(HullFigures.money(watch.plate.monthLoad, code: watch.plate.currencyCode))
                        .hullText(.load)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Cancel-savings")
                        .hullText(.stencil)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(HullFigures.money(watch.plate.cancelSavings, code: watch.plate.currencyCode))
                        .hullText(.title)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .id(dayStamp)
            Text(jobLine)
                .hullText(.body)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            HStack(spacing: HullSwatch.space(1)) {
                HullChromeButton(title: "Insights", fillsWidth: true) { showInsights = true }
                HullChromeButton(title: "Settings", fillsWidth: true) { showSettings = true }
            }
        }
        .padding(.horizontal, HullSwatch.space(2))
        .padding(.top, HullSwatch.space(1))
        .padding(.bottom, HullSwatch.space(1))
        .background {
            Image("ktl_HeaderDecor")
                .resizable()
                .scaledToFill()
                .opacity(0.28)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .clipped()
    }

    private var jobLine: String {
        if watch.beam.pendingCut != nil {
            return "Seat the loose credit on a keep or a named sink."
        }
        if let post = watch.plate.leadingCut {
            return "This month's charges. Jettison \(post.name), then seat the credit."
        }
        return "This month's charges stand on the beam."
    }

    private var populated: some View {
        VStack(spacing: 0) {
            if let fault = watch.fault, watch.warning != .startedEmpty {
                HStack {
                    Text(fault)
                        .hullText(.caption)
                        .foregroundStyle(HullSwatch.accent)
                    Spacer(minLength: HullSwatch.space(1))
                    HullChromeButton(title: "Retry") {
                        Task { await watch.retry() }
                    }
                }
                .padding(.horizontal, HullSwatch.space(2))
            }
            GeometryReader { geo in
                LoadPlateHost(
                    frame: watch.plate,
                    onPrepare: { id in
                        Task { await watch.prepare(brickID: id) }
                    },
                    onSeat: { berth in
                        Task { await markSeated(berth) }
                    },
                    onAbandon: {
                        Task { await watch.abandon() }
                    },
                    onExpand: { id in
                        watch.beginEdit(id)
                    }
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if watch.beam.pendingCut != nil {
                pendingBar
            } else if watch.isAdding || watch.expandingBrickID != nil {
                ScrollView {
                    BrickDraft(
                        brick: draftBrick,
                        currencyCode: watch.plate.currencyCode,
                        onSave: { brick in
                            Task { await watch.saveBrick(brick) }
                        },
                        onCancel: { watch.cancelDraft() }
                    )
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                idleBar
            }
        }
    }

    private var idleBar: some View {
        VStack(spacing: HullSwatch.space(1)) {
            if let post = watch.plate.leadingCut {
                HullFillButton(
                    title: "Jettison \(post.name)",
                    detail: "Then seat \(HullFigures.money(post.load, code: watch.plate.currencyCode)) on a keep or sink",
                    enabled: !watch.isHauling
                ) {
                    Task { await watch.prepare(brickID: post.id) }
                }
            }
            Button {
                watch.beginAdd()
            } label: {
                Text("Stand a brick")
                    .hullText(.body)
                    .foregroundStyle(HullSwatch.ink)
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(watch.isHauling)
            .accessibilityLabel("Stand a brick")
        }
        .padding(.horizontal, HullSwatch.space(2))
        .padding(.bottom, HullSwatch.space(2))
    }

    private var pendingBar: some View {
        HStack(spacing: HullSwatch.space(1)) {
            HullChromeButton(title: "Abandon", fillsWidth: true) {
                Task { await watch.abandon() }
            }
            HullChromeButton(title: "Name a sink", fillsWidth: true) {
                showSinkName = true
            }
        }
        .padding(.horizontal, HullSwatch.space(2))
        .padding(.bottom, HullSwatch.space(2))
    }

    private var draftBrick: ChargeBrick? {
        guard let id = watch.expandingBrickID else { return nil }
        return watch.beam.bricks.first(where: { $0.id == id })
    }

    private func markSeated(_ berth: CreditBerth) async {
        await watch.seat(on: berth)
        guard watch.fault == nil else { return }
        successTask?.cancel()
        successTask = Task {
            showSuccess = true
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            showSuccess = false
        }
    }

    private func applyReview() {
        guard let review = watch.consumeReview() else { return }
        var insights = false
        var settings = false
        BeamLaunch.bind(review, insights: &insights, settings: &settings)
        showInsights = insights
        showSettings = settings
    }
}
