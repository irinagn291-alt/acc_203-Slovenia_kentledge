import XCTest
@testable import Kentledge

@MainActor
final class BeamWatchTests: XCTestCase {
    func test_viewsObserveOneBeam() async throws {
        let watch = BeamWatch.previewPopulated()
        let ledger = LedgerView(watch: watch, handlesLaunch: false)
        let insights = InsightsView(watch: watch)
        let settings = SettingsView(watch: watch)
        let credit = SeatCreditView(watch: watch)
        XCTAssertTrue(ledger.watch === watch)
        XCTAssertTrue(insights.watch === watch)
        XCTAssertTrue(settings.watch === watch)
        XCTAssertTrue(credit.watch === watch)

        await watch.prepare(brickID: BeamSeed.weeklyID)
        XCTAssertEqual(ledger.watch.beam.pendingCut?.brickID, BeamSeed.weeklyID)
        XCTAssertEqual(insights.watch.beam.pendingCut?.brickID, BeamSeed.weeklyID)
        XCTAssertEqual(settings.watch.beam.bricks.count, 3)
    }

    func test_watch_prepareSeatAbandon_twoPhase() async throws {
        let watch = BeamWatch.previewPopulated()
        let before = watch.beam.monthlyLoad
        XCTAssertNil(watch.beam.pendingCut)

        await watch.prepare(brickID: BeamSeed.weeklyID)
        XCTAssertEqual(watch.beam.pendingCut?.brickID, BeamSeed.weeklyID)
        XCTAssertEqual(watch.beam.monthlyLoad, before, accuracy: 1e-12)
        XCTAssertEqual(watch.beam.cancelSavings, 0)
        XCTAssertEqual(watch.plate.posts.first(where: { $0.id == BeamSeed.weeklyID })?.ghosted, true)

        await watch.abandon()
        XCTAssertNil(watch.beam.pendingCut)
        XCTAssertEqual(watch.beam.bricks.count, 3)

        await watch.prepare(brickID: BeamSeed.weeklyID)
        await watch.seat(on: .sink(BeamSeed.sinkID))
        XCTAssertNil(watch.beam.pendingCut)
        XCTAssertFalse(watch.beam.bricks.contains(where: { $0.id == BeamSeed.weeklyID }))
        XCTAssertEqual(watch.beam.cancelSavings, 9.99 * (52.0 / 12.0), accuracy: 1e-12)
        XCTAssertEqual(watch.beam.monthlyLoad, before - 9.99 * (52.0 / 12.0), accuracy: 1e-12)
    }

    func test_watch_cannotSeatOnGhost() async {
        let watch = BeamWatch.previewPopulated()
        await watch.prepare(brickID: BeamSeed.weeklyID)
        await watch.seat(on: .keep(BeamSeed.weeklyID))
        XCTAssertEqual(watch.beam.pendingCut?.brickID, BeamSeed.weeklyID)
        XCTAssertEqual(watch.beam.bricks.count, 3)
        XCTAssertNotNil(watch.fault)
    }

    func test_familyInvariant_plateForecastChargeMonthOnly() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let august = BeamSeed.chargeDay(year: 2026, month: 8, day: 15)
        let january = BeamSeed.chargeDay(year: 2027, month: 1, day: 15)
        let watch = BeamWatch(
            store: HoldBeam(beam: BeamSeed.beam()),
            calendar: calendar,
            now: { august },
            beam: BeamSeed.beam(),
            shouldLoad: false
        )
        XCTAssertEqual(watch.plate.posts.map(\.id), [BeamSeed.weeklyID, BeamSeed.monthlyID, BeamSeed.yearlyID])
        let weeklyLoad = watch.plate.posts.first(where: { $0.id == BeamSeed.weeklyID })?.load ?? -1
        XCTAssertEqual(weeklyLoad, 9.99 * (52.0 / 12.0), accuracy: 1e-12)

        let winter = BeamWatch(
            store: HoldBeam(beam: BeamSeed.beam()),
            calendar: calendar,
            now: { january },
            beam: BeamSeed.beam(),
            shouldLoad: false
        )
        XCTAssertEqual(winter.plate.posts.map(\.id), [BeamSeed.weeklyID, BeamSeed.monthlyID])
        XCTAssertFalse(winter.plate.posts.contains(where: { $0.id == BeamSeed.yearlyID }))
    }
}

@MainActor
final class BeamReviewTests: XCTestCase {
    func test_reviewLaunch_onceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            BeamLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = BeamLaunch.consume(
            arguments: ["-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertTrue(consumed)

        let second = BeamLaunch.consume(
            arguments: ["-ReviewScreen", "goals"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertNil(second)

        var insights = false
        var settings = false
        BeamLaunch.bind(.log, insights: &insights, settings: &settings)
        XCTAssertTrue(insights)
        XCTAssertFalse(settings)
        BeamLaunch.bind(.goals, insights: &insights, settings: &settings)
        XCTAssertTrue(settings)
        XCTAssertFalse(insights)
        BeamLaunch.bind(.today, insights: &insights, settings: &settings)
        XCTAssertFalse(insights)
        XCTAssertFalse(settings)
    }
}

@MainActor
final class ScreenFactoryTests: XCTestCase {
    func test_mainScreensConstructWithNoArguments() {
        _ = LedgerView()
        _ = InsightsView()
        _ = SettingsView()
        _ = OnboardingView()
        _ = SeatCreditView()
        _ = BrickDraft()
        _ = ContentView()
    }
}
