import Foundation

/// Role: Beam. In-memory hold for previews and presentation tests. Not a second document.
actor HoldBeam: BeamStoring {
    private var latest: LoadBeam
    private var warning: BeamWarning?

    init(beam: LoadBeam = .vacant, warning: BeamWarning? = nil) {
        self.latest = beam
        self.warning = warning
    }

    func load() async -> (beam: LoadBeam, warning: BeamWarning?) {
        (latest, warning)
    }

    func beam() async -> LoadBeam {
        latest
    }

    func addBrick(_ brick: ChargeBrick) async throws -> LoadBeam {
        latest = try latest.adding(brick)
        return latest
    }

    func addSink(_ sink: NamedSink) async throws -> LoadBeam {
        latest = try latest.addingSink(sink)
        return latest
    }

    func setBallast(_ ballast: BeamBallast) async throws -> LoadBeam {
        latest = latest.settingBallast(ballast)
        return latest
    }

    func prepare(brickID: UUID) async throws -> LoadBeam {
        latest = try latest.preparing(brickID: brickID)
        return latest
    }

    func seat(on berth: CreditBerth) async throws -> LoadBeam {
        latest = try latest.seating(on: berth)
        return latest
    }

    func abandon() async throws -> LoadBeam {
        latest = try latest.abandoning()
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .vacant
        warning = nil
    }

    func seedDemoIfNeeded() async throws -> LoadBeam? {
        nil
    }
}
