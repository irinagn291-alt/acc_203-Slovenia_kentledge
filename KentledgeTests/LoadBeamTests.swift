import XCTest
@testable import Kentledge

final class LoadBeamTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
    }

    func test_familyInvariant_monthlyEquivalentAndChargeMonthOnly() {
        let weekly = ChargeBrick(
            id: BeamSeed.weeklyID,
            name: "Chain sling",
            amount: 9.99,
            period: .weekly,
            nextChargeDay: day(2026, 8, 4)
        )
        XCTAssertEqual(ChargePeriod.weekly.occurrencesPerMonth, 52.0 / 12.0, accuracy: 1e-12)
        XCTAssertEqual(weekly.monthlyEquivalent, 9.99 * weekly.period!.occurrencesPerMonth, accuracy: 1e-12)
        XCTAssertEqual(weekly.monthlyEquivalent, 9.99 * (52.0 / 12.0), accuracy: 1e-12)

        let yearly = ChargeBrick(
            id: BeamSeed.yearlyID,
            name: "Dry-dock berth",
            amount: 120,
            period: .yearly,
            nextChargeDay: day(2026, 8, 20)
        )
        XCTAssertEqual(yearly.monthlyEquivalent, 120 * (1.0 / 12.0), accuracy: 1e-12)
        XCTAssertTrue(yearly.appearsInChargeMonth(day(2026, 8, 1), calendar: calendar))
        XCTAssertFalse(yearly.appearsInChargeMonth(day(2026, 7, 1), calendar: calendar))
        XCTAssertFalse(yearly.appearsInChargeMonth(day(2027, 1, 1), calendar: calendar))
        XCTAssertTrue(yearly.appearsInChargeMonth(day(2027, 8, 1), calendar: calendar))

        let beam = LoadBeam(
            bricks: [weekly, yearly],
            seatedCredits: [],
            sinks: [],
            ballast: .vacant,
            pendingCut: nil
        )
        let august = beam.forecastBricks(in: day(2026, 8, 1), calendar: calendar)
        let january = beam.forecastBricks(in: day(2027, 1, 1), calendar: calendar)
        XCTAssertEqual(august.map(\.id), [weekly.id, yearly.id])
        XCTAssertEqual(january.map(\.id), [weekly.id])
    }

    func test_prepareSeatAbandon_emptyPopulatedInvalid() throws {
        let keep = ChargeBrick(
            id: BeamSeed.monthlyID,
            name: "Hull plate",
            amount: 14,
            period: .monthly,
            nextChargeDay: day(2026, 8, 12)
        )
        let cut = ChargeBrick(
            id: BeamSeed.weeklyID,
            name: "Chain sling",
            amount: 9.99,
            period: .weekly,
            nextChargeDay: day(2026, 8, 4)
        )
        let sink = NamedSink(id: BeamSeed.sinkID, name: "Plate locker")
        var beam = LoadBeam(
            bricks: [keep, cut],
            seatedCredits: [],
            sinks: [sink],
            ballast: .vacant,
            pendingCut: nil
        )
        let loadBefore = beam.monthlyLoad

        do {
            _ = try beam.seating(on: .sink(sink.id))
            XCTFail("expected noPendingCredit")
        } catch {
            XCTAssertEqual(error as? BeamFault, .noPendingCredit)
        }

        beam = try beam.preparing(brickID: cut.id)
        XCTAssertEqual(beam.pendingCut?.brickID, cut.id)
        XCTAssertEqual(beam.pendingCut?.monthlyEquivalent ?? -1, cut.monthlyEquivalent, accuracy: 1e-12)
        XCTAssertEqual(beam.monthlyLoad, loadBefore, accuracy: 1e-12)
        XCTAssertEqual(beam.cancelSavings, 0)
        XCTAssertEqual(beam.keeps.map(\.brickID), [keep.id])

        do {
            _ = try beam.seating(on: .keep(cut.id))
            XCTFail("expected cannotSeatOnGhost")
        } catch {
            XCTAssertEqual(error as? BeamFault, .cannotSeatOnGhost)
        }
        do {
            _ = try beam.seating(on: .sink(UUID()))
            XCTFail("expected unknownSink")
        } catch {
            XCTAssertEqual(error as? BeamFault, .unknownSink)
        }

        let abandoned = try beam.abandoning()
        XCTAssertNil(abandoned.pendingCut)
        XCTAssertEqual(abandoned.bricks.count, 2)
        XCTAssertEqual(abandoned.cancelSavings, 0)

        let seated = try beam.seating(on: .sink(sink.id))
        XCTAssertNil(seated.pendingCut)
        XCTAssertEqual(seated.bricks.map(\.id), [keep.id])
        XCTAssertEqual(seated.cancelSavings, cut.monthlyEquivalent, accuracy: 1e-12)
        XCTAssertEqual(seated.monthlyLoad, keep.monthlyEquivalent, accuracy: 1e-12)
        XCTAssertEqual(seated.seatedCredits.first?.berth, .sink(sink.id))
    }

    func test_twoPhaseCut_noCanceledFlagOnBrick() throws {
        let labels = Mirror(reflecting: ChargeBrick(
            name: "Hull plate",
            amount: 14,
            period: .monthly,
            nextChargeDay: day(2026, 8, 12)
        )).children.compactMap(\.label)
        XCTAssertFalse(labels.contains { $0.localizedCaseInsensitiveContains("cancel") })

        let cut = ChargeBrick(
            id: BeamSeed.weeklyID,
            name: "Chain sling",
            amount: 5,
            period: .monthly,
            nextChargeDay: day(2026, 8, 4)
        )
        let keep = ChargeBrick(
            id: BeamSeed.monthlyID,
            name: "Hull plate",
            amount: 10,
            period: .monthly,
            nextChargeDay: day(2026, 8, 12)
        )
        let prepared = try LoadBeam(
            bricks: [cut, keep],
            seatedCredits: [],
            sinks: [],
            ballast: .vacant,
            pendingCut: nil
        ).preparing(brickID: cut.id)
        let seated = try prepared.seating(on: .keep(keep.id))
        XCTAssertEqual(seated.seatedCredits.count, 1)
        XCTAssertFalse(seated.bricks.contains(where: { $0.id == cut.id }))
    }

    func test_addRejectsEmptyAndNonPositive() {
        var beam = LoadBeam.vacant
        do {
            beam = try beam.adding(ChargeBrick(name: "  ", amount: 4, period: .monthly, nextChargeDay: day(2026, 8, 1)))
            XCTFail("expected emptyName")
        } catch {
            XCTAssertEqual(error as? BeamFault, .emptyName)
        }
        do {
            beam = try beam.adding(ChargeBrick(name: "Hull", amount: 0, period: .monthly, nextChargeDay: day(2026, 8, 1)))
            XCTFail("expected nonPositiveAmount")
        } catch {
            XCTAssertEqual(error as? BeamFault, .nonPositiveAmount)
        }
        XCTAssertTrue(beam.bricks.isEmpty)
    }

    func test_mysteryFlag_missingPeriodOrDuplicateDay() {
        let lone = ChargeBrick(
            id: UUID(),
            name: "Unknown hoist",
            amount: 8,
            period: nil,
            nextChargeDay: day(2026, 8, 9)
        )
        let first = ChargeBrick(
            id: UUID(),
            name: "A",
            amount: 3,
            period: .monthly,
            nextChargeDay: day(2026, 8, 15)
        )
        let twin = ChargeBrick(
            id: UUID(),
            name: "B",
            amount: 4,
            period: .monthly,
            nextChargeDay: day(2026, 8, 15)
        )
        let unique = ChargeBrick(
            id: UUID(),
            name: "C",
            amount: 5,
            period: .monthly,
            nextChargeDay: day(2026, 8, 16)
        )
        let beam = LoadBeam(
            bricks: [lone, first, twin, unique],
            seatedCredits: [],
            sinks: [],
            ballast: .vacant,
            pendingCut: nil
        )
        let flagged = beam.mysteryBrickIDs(calendar: calendar)
        XCTAssertTrue(flagged.contains(lone.id))
        XCTAssertTrue(flagged.contains(first.id))
        XCTAssertTrue(flagged.contains(twin.id))
        XCTAssertFalse(flagged.contains(unique.id))
    }

    func test_insightsRanksUncutByWhatTheyWouldFree() throws {
        let small = ChargeBrick(
            id: UUID(),
            name: "Zinc",
            amount: 6,
            period: .monthly,
            nextChargeDay: day(2026, 8, 2)
        )
        let large = ChargeBrick(
            id: UUID(),
            name: "Primer",
            amount: 30,
            period: .monthly,
            nextChargeDay: day(2026, 8, 3)
        )
        let beam = try LoadBeam.vacant
            .adding(small)
            .adding(large)
        XCTAssertEqual(beam.uncutRankedByFreeing().map(\.id), [large.id, small.id])
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
