import Foundation

/// Role: Beam. Two-phase cut faults. Views never invent a canceled flag.
enum BeamFault: Error, Equatable, Sendable {
    case unknownBrick
    case alreadyPrepared
    case noPendingCredit
    case emptyName
    case nonPositiveAmount
    case unknownKeep
    case unknownSink
    case cannotSeatOnGhost
}

/// Role: Beam. Currency and reminder on the ledger. Not a second document.
struct BeamBallast: Equatable, Sendable {
    var currencyCode: String
    var reminderEnabled: Bool
    var reminderHour: Int
    var onboardingComplete: Bool

    static let vacant = BeamBallast(
        currencyCode: "USD",
        reminderEnabled: false,
        reminderHour: 9,
        onboardingComplete: false
    )
}

/// Role: Beam. The single document. Prepare is not a write; seat and abandon are the only commits.
struct LoadBeam: Equatable, Sendable {
    var bricks: [ChargeBrick]
    var seatedCredits: [SeatCredit]
    var sinks: [NamedSink]
    var ballast: BeamBallast
    var pendingCut: SeatCredit?

    static let vacant = LoadBeam(
        bricks: [],
        seatedCredits: [],
        sinks: [],
        ballast: .vacant,
        pendingCut: nil
    )

    var monthlyLoad: Double {
        bricks.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var cancelSavings: Double {
        seatedCredits.reduce(0) { $0 + $1.monthlyEquivalent }
    }

    var keeps: [Keep] {
        bricks.compactMap { brick in
            guard brick.id != pendingCut?.brickID else { return nil }
            return Keep(brick: brick)
        }
    }

    func forecastBricks(in date: Date, calendar: Calendar) -> [ChargeBrick] {
        bricks.filter { $0.appearsInChargeMonth(date, calendar: calendar) }
    }

    func mysteryBrickIDs(calendar: Calendar) -> Set<UUID> {
        var flagged: Set<UUID> = []
        var days: [Int: [UUID]] = [:]
        for brick in bricks {
            if brick.period == nil {
                flagged.insert(brick.id)
            }
            let day = calendar.component(.day, from: brick.nextChargeDay)
            days[day, default: []].append(brick.id)
        }
        for ids in days.values where ids.count > 1 {
            flagged.formUnion(ids)
        }
        return flagged
    }

    func uncutRankedByFreeing() -> [ChargeBrick] {
        bricks
            .filter { $0.id != pendingCut?.brickID }
            .sorted { lhs, rhs in
                if lhs.monthlyEquivalent != rhs.monthlyEquivalent {
                    return lhs.monthlyEquivalent > rhs.monthlyEquivalent
                }
                return lhs.name < rhs.name
            }
    }

    func adding(_ brick: ChargeBrick) throws -> LoadBeam {
        var nextBrick = brick
        nextBrick.name = nextBrick.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nextBrick.name.isEmpty else { throw BeamFault.emptyName }
        guard nextBrick.amount > 0 else { throw BeamFault.nonPositiveAmount }
        var next = self
        if let index = next.bricks.firstIndex(where: { $0.id == nextBrick.id }) {
            next.bricks[index] = nextBrick
        } else {
            next.bricks.append(nextBrick)
        }
        return next
    }

    func addingSink(_ sink: NamedSink) throws -> LoadBeam {
        var nextSink = sink
        nextSink.name = nextSink.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nextSink.name.isEmpty else { throw BeamFault.emptyName }
        var next = self
        if let index = next.sinks.firstIndex(where: { $0.id == nextSink.id }) {
            next.sinks[index] = nextSink
        } else {
            next.sinks.append(nextSink)
        }
        return next
    }

    func settingBallast(_ ballast: BeamBallast) -> LoadBeam {
        var next = self
        next.ballast = ballast
        return next
    }

    func preparing(brickID: UUID) throws -> LoadBeam {
        if pendingCut != nil { throw BeamFault.alreadyPrepared }
        guard let brick = bricks.first(where: { $0.id == brickID }) else {
            throw BeamFault.unknownBrick
        }
        var next = self
        next.pendingCut = SeatCredit(
            id: UUID(),
            brickID: brick.id,
            monthlyEquivalent: brick.monthlyEquivalent,
            berth: nil
        )
        return next
    }

    func seating(on berth: CreditBerth) throws -> LoadBeam {
        guard var credit = pendingCut else { throw BeamFault.noPendingCredit }
        switch berth {
        case .keep(let keepID):
            if keepID == credit.brickID { throw BeamFault.cannotSeatOnGhost }
            guard keeps.contains(where: { $0.brickID == keepID }) else {
                throw BeamFault.unknownKeep
            }
        case .sink(let sinkID):
            guard sinks.contains(where: { $0.id == sinkID }) else {
                throw BeamFault.unknownSink
            }
        }
        credit.berth = berth
        var next = self
        next.bricks.removeAll { $0.id == credit.brickID }
        next.seatedCredits.append(credit)
        next.pendingCut = nil
        return next
    }

    func abandoning() throws -> LoadBeam {
        guard pendingCut != nil else { throw BeamFault.noPendingCredit }
        var next = self
        next.pendingCut = nil
        return next
    }
}
