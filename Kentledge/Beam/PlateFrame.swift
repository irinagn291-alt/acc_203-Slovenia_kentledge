import Foundation

/// Role: Beam. One frame the plate reads. Owns none of the document.
struct PlatePost: Sendable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var load: Double
    var detail: String
    var ghosted: Bool
    var mystery: Bool
}

/// Role: Keep. A remaining post the pending credit may land on.
struct KeepPost: Sendable, Equatable, Identifiable {
    var id: UUID
    var brickID: UUID
    var name: String
}

/// Role: Sink. A named plate the pending credit may lock onto.
struct SinkBerth: Sendable, Equatable, Identifiable {
    var id: UUID
    var name: String
}

/// Role: Beam. Projection of this month's posts, keeps, sinks, and the pending credit.
struct PlateFrame: Sendable, Equatable {
    var monthLoad: Double
    var cancelSavings: Double
    var currencyCode: String
    var posts: [PlatePost]
    var keeps: [KeepPost]
    var sinks: [SinkBerth]
    var pendingLoad: Double?
    var pendingBrickID: UUID?

    static let vacant = PlateFrame(
        monthLoad: 0,
        cancelSavings: 0,
        currencyCode: "USD",
        posts: [],
        keeps: [],
        sinks: [],
        pendingLoad: nil,
        pendingBrickID: nil
    )

    /// Heaviest live post — the seeded cut a stranger should take next.
    var leadingCut: PlatePost? {
        posts.filter { !$0.ghosted }.max { lhs, rhs in
            if lhs.load != rhs.load { return lhs.load < rhs.load }
            return lhs.name > rhs.name
        }
    }

    var seatTargets: [(CreditBerth, String, Bool)] {
        var rows: [(CreditBerth, String, Bool)] = []
        for keep in keeps {
            rows.append((.keep(keep.brickID), keep.name, false))
        }
        for sink in sinks {
            rows.append((.sink(sink.id), sink.name, true))
        }
        return rows
    }
}

enum PlatePlot {
    /// Forecast posts land only in the charge month. monthlyEquivalent is amount × occurrencesPerMonth.
    @MainActor
    static func frame(
        from beam: LoadBeam,
        now: Date,
        calendar: Calendar = .current
    ) -> PlateFrame {
        let mystery = beam.mysteryBrickIDs(calendar: calendar)
        let posts = beam.forecastBricks(in: now, calendar: calendar).map { brick in
            PlatePost(
                id: brick.id,
                name: brick.name,
                load: brick.monthlyEquivalent,
                detail: BeamMath.periodLine(
                    period: brick.period,
                    nextChargeDay: brick.nextChargeDay,
                    calendar: calendar
                ),
                ghosted: beam.pendingCut?.brickID == brick.id,
                mystery: mystery.contains(brick.id)
            )
        }
        return PlateFrame(
            monthLoad: beam.monthlyLoad,
            cancelSavings: beam.cancelSavings,
            currencyCode: beam.ballast.currencyCode,
            posts: posts,
            keeps: beam.keeps.map { KeepPost(id: $0.id, brickID: $0.brickID, name: $0.name) },
            sinks: beam.sinks.map { SinkBerth(id: $0.id, name: $0.name) },
            pendingLoad: beam.pendingCut?.monthlyEquivalent,
            pendingBrickID: beam.pendingCut?.brickID
        )
    }
}
