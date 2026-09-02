import XCTest
@testable import Kentledge

final class BeamMathTests: XCTestCase {
    func test_periodLineAndShareSummary() {
        let day = BeamSeed.chargeDay(year: 2026, month: 8, day: 12)
        let line = BeamMath.periodLine(period: .monthly, nextChargeDay: day)
        XCTAssertTrue(line.hasPrefix("Month ·"))
        XCTAssertTrue(
            BeamMath.periodLine(period: nil, nextChargeDay: day).hasPrefix("Once ·")
        )
        let slices = BeamMath.loadSlices(from: [
            (BeamSeed.weeklyID, "Streaming", 43.29),
            (BeamSeed.monthlyID, "Gym pass", 14),
            (BeamSeed.yearlyID, "Cloud backup", 10),
        ])
        XCTAssertEqual(slices.count, 3)
        XCTAssertEqual(slices.first?.name, "Streaming")
        XCTAssertEqual(slices.map(\.share).reduce(0, +), 1, accuracy: 1e-9)
        let share = BeamMath.shareSummary(
            monthLoad: 67.29,
            yearLoad: 807.48,
            savedMonth: 14,
            chargeCount: 3,
            cutCount: 1,
            currencyCode: "USD"
        )
        XCTAssertTrue(share.contains("3 charges"))
        XCTAssertTrue(share.contains("1 cut"))
        XCTAssertTrue(share.contains("Kentledge"))
    }

    func test_yearlyLoadFollowsMonthly() {
        let beam = BeamSeed.beam()
        XCTAssertEqual(beam.yearlyLoad, beam.monthlyLoad * 12, accuracy: 1e-9)
    }
}
