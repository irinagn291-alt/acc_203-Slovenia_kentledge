import Foundation
import UIKit

/// Role: Beam. The single object every view observes. Prepare is not a write; seat and abandon commit.
@MainActor
final class BeamWatch: ObservableObject {
    @Published private(set) var beam: LoadBeam
    @Published private(set) var warning: BeamWarning?
    @Published private(set) var fault: String?
    @Published private(set) var isHauling = false
    @Published var expandingBrickID: UUID?
    @Published var isAdding = false

    let store: any BeamStoring
    private let calendar: Calendar
    private let now: () -> Date
    private let shouldLoad: Bool
    private var appeared = false
    private var reviewConsumed = false
    private var haulStarted: Date?

    init(
        store: any BeamStoring,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { Date() },
        beam: LoadBeam = .vacant,
        warning: BeamWarning? = nil,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.beam = beam
        self.warning = warning
        self.shouldLoad = shouldLoad
    }

    var plate: PlateFrame {
        PlatePlot.frame(from: beam, now: now(), calendar: calendar)
    }

    var onboardingComplete: Bool {
        beam.ballast.onboardingComplete
    }

    func appear() async {
        guard shouldLoad else { return }
        if appeared {
            return
        }
        appeared = true
        await haul()
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = "The ledger could not be written."
        }
    }

    func prepare(brickID: UUID) async {
        await run {
            self.beam = try await self.store.prepare(brickID: brickID)
        }
    }

    func seat(on berth: CreditBerth) async {
        await run {
            self.beam = try await self.store.seat(on: berth)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func abandon() async {
        await run {
            self.beam = try await self.store.abandon()
        }
    }

    func saveBrick(_ brick: ChargeBrick) async {
        await run {
            self.beam = try await self.store.addBrick(brick)
            self.expandingBrickID = nil
            self.isAdding = false
        }
    }

    func saveSink(_ sink: NamedSink) async {
        await run {
            self.beam = try await self.store.addSink(sink)
        }
    }

    func saveBallast(_ ballast: BeamBallast) async {
        await run {
            self.beam = try await self.store.setBallast(ballast)
        }
    }

    func finishOnboarding(skipped: Bool) async {
        var ballast = beam.ballast
        if skipped {
            ballast.currencyCode = BeamBallast.vacant.currencyCode
            ballast.reminderEnabled = false
            ballast.reminderHour = 9
        }
        ballast.onboardingComplete = true
        await saveBallast(ballast)
    }

    func reopenOnboarding() async {
        var ballast = beam.ballast
        ballast.onboardingComplete = false
        await saveBallast(ballast)
    }

    func resetAll() async {
        await run {
            try await self.store.resetAllData()
            self.beam = .vacant
            self.warning = nil
            self.expandingBrickID = nil
            self.isAdding = false
        }
    }

    func consumeReview(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) -> BeamReview? {
        BeamLaunch.consume(
            arguments: arguments,
            onboardingComplete: onboardingComplete,
            consumed: &reviewConsumed
        )
    }

    func beginAdd() {
        isAdding = true
        expandingBrickID = nil
    }

    func beginEdit(_ id: UUID) {
        isAdding = false
        expandingBrickID = id
    }

    func cancelDraft() {
        isAdding = false
        expandingBrickID = nil
    }

    static func live() -> BeamWatch {
        let directory: URL
        if let support = try? BeamStore.applicationSupportDirectory() {
            directory = support
        } else {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Kentledge",
                isDirectory: true
            )
        }
        return BeamWatch(store: BeamStore(directory: directory))
    }

    static func previewPopulated() -> BeamWatch {
        BeamWatch(
            store: HoldBeam(beam: BeamSeed.beam()),
            beam: BeamSeed.beam(),
            shouldLoad: false
        )
    }

    static func previewEmpty() -> BeamWatch {
        var ballast = BeamBallast.vacant
        ballast.onboardingComplete = true
        let beam = LoadBeam.vacant.settingBallast(ballast)
        return BeamWatch(store: HoldBeam(beam: beam), beam: beam, shouldLoad: false)
    }

    static func previewError() -> BeamWatch {
        var ballast = BeamBallast.vacant
        ballast.onboardingComplete = true
        let beam = LoadBeam.vacant.settingBallast(ballast)
        return BeamWatch(
            store: HoldBeam(beam: beam, warning: .startedEmpty),
            beam: beam,
            warning: .startedEmpty,
            shouldLoad: false
        )
    }

    static func previewPending() -> BeamWatch {
        let seeded = BeamSeed.beam()
        let prepared = (try? seeded.preparing(brickID: BeamSeed.weeklyID)) ?? seeded
        return BeamWatch(store: HoldBeam(beam: prepared), beam: prepared, shouldLoad: false)
    }

    private func haul() async {
        let started = Date()
        haulStarted = started
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulStarted == started else { return }
            self.isHauling = true
        }
        let loaded = await store.load()
        beam = loaded.beam
        warning = loaded.warning
        if let seeded = try? await store.seedDemoIfNeeded() {
            beam = seeded
        }
        haulStarted = nil
        isHauling = false
        if warning == .startedEmpty {
            fault = "The ledger was unreadable. The beam is empty."
        } else if warning == .recoveredFromBackup {
            fault = "Recovered the last good ledger."
        }
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        do {
            fault = nil
            try await work()
        } catch let fault as BeamFault {
            self.fault = Self.copy(fault)
        } catch {
            self.fault = "Something went wrong. Try again."
        }
    }

    private static func copy(_ fault: BeamFault) -> String {
        switch fault {
        case .unknownBrick:
            "That charge is not on the list."
        case .alreadyPrepared:
            "Finish placing the freed money, or undo the cancel."
        case .noPendingCredit:
            "Nothing is free to place yet. Cancel a charge first."
        case .emptyName:
            "Give it a name before saving."
        case .nonPositiveAmount:
            "Amount must be greater than zero."
        case .unknownKeep:
            "That charge is no longer on the list."
        case .unknownSink:
            "That savings name is gone."
        case .cannotSeatOnGhost:
            "Put the money on a different charge, not the one you canceled."
        }
    }
}
