import Foundation

/// Role: Beam. Simulator demo load. Device never writes this. Key: ktl.demo.v2.
enum BeamSeed {
    static let weeklyID = uuid("11111111-1111-4111-8111-111111111111")
    static let monthlyID = uuid("22222222-2222-4222-8222-222222222222")
    static let yearlyID = uuid("33333333-3333-4333-8333-333333333333")
    static let sinkID = uuid("44444444-4444-4444-8444-444444444444")

    /// Seed identities are literals. Failure here is a programmer error.
    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func chargeDay(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        if let utc = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = utc
        }
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    static func beam() -> LoadBeam {
        let weekly = ChargeBrick(
            id: weeklyID,
            name: "Streaming",
            amount: 9.99,
            period: .weekly,
            nextChargeDay: chargeDay(year: 2026, month: 8, day: 4)
        )
        let monthly = ChargeBrick(
            id: monthlyID,
            name: "Gym pass",
            amount: 14,
            period: .monthly,
            nextChargeDay: chargeDay(year: 2026, month: 8, day: 12)
        )
        let yearly = ChargeBrick(
            id: yearlyID,
            name: "Cloud backup",
            amount: 120,
            period: .yearly,
            nextChargeDay: chargeDay(year: 2026, month: 8, day: 20)
        )
        let sink = NamedSink(id: sinkID, name: "Emergency fund")
        var ballast = BeamBallast.vacant
        ballast.onboardingComplete = true
        return LoadBeam(
            bricks: [weekly, monthly, yearly],
            seatedCredits: [],
            sinks: [sink],
            ballast: ballast,
            pendingCut: nil
        )
    }
}
