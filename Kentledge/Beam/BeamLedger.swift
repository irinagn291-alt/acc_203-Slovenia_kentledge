import Foundation

/// Role: Beam. On-disk / UserDefaults envelope. Domain types never decode this JSON themselves.
struct BeamLedger: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var bricks: [BrickRecord]
    var credits: [CreditRecord]
    var sinks: [SinkRecord]
    var ballast: BallastRecord

    static func committed(from beam: LoadBeam) -> BeamLedger {
        BeamLedger(
            schemaVersion: BeamCodec.currentSchema,
            bricks: beam.bricks.map { brick in
                BrickRecord(
                    id: brick.id,
                    name: brick.name,
                    amount: brick.amount,
                    period: brick.period?.rawValue,
                    nextChargeEpoch: brick.nextChargeDay.timeIntervalSince1970
                )
            },
            credits: beam.seatedCredits.compactMap { credit in
                guard let berth = credit.berth else { return nil }
                let kind: String
                let berthID: UUID
                switch berth {
                case .keep(let id):
                    kind = "keep"
                    berthID = id
                case .sink(let id):
                    kind = "sink"
                    berthID = id
                }
                return CreditRecord(
                    id: credit.id,
                    brickID: credit.brickID,
                    title: credit.title,
                    monthlyEquivalent: credit.monthlyEquivalent,
                    berthKind: kind,
                    berthID: berthID
                )
            },
            sinks: beam.sinks.map { SinkRecord(id: $0.id, name: $0.name) },
            ballast: BallastRecord(
                currencyCode: beam.ballast.currencyCode,
                reminderEnabled: beam.ballast.reminderEnabled,
                reminderHour: beam.ballast.reminderHour,
                onboardingComplete: beam.ballast.onboardingComplete
            )
        )
    }

    func asBeam() -> LoadBeam {
        LoadBeam(
            bricks: bricks.map { record in
                ChargeBrick(
                    id: record.id,
                    name: record.name,
                    amount: record.amount,
                    period: record.period.flatMap(ChargePeriod.init(rawValue:)),
                    nextChargeDay: Date(timeIntervalSince1970: record.nextChargeEpoch)
                )
            },
            seatedCredits: credits.compactMap { record in
                let berth: CreditBerth?
                switch record.berthKind {
                case "keep":
                    berth = .keep(record.berthID)
                case "sink":
                    berth = .sink(record.berthID)
                default:
                    berth = nil
                }
                guard let berth else { return nil }
                return SeatCredit(
                    id: record.id,
                    brickID: record.brickID,
                    title: record.title ?? "Cut charge",
                    monthlyEquivalent: record.monthlyEquivalent,
                    berth: berth
                )
            },
            sinks: sinks.map { NamedSink(id: $0.id, name: $0.name) },
            ballast: BeamBallast(
                currencyCode: ballast.currencyCode,
                reminderEnabled: ballast.reminderEnabled,
                reminderHour: ballast.reminderHour,
                onboardingComplete: ballast.onboardingComplete
            ),
            pendingCut: nil
        )
    }
}

struct BrickRecord: Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var amount: Double
    var period: String?
    var nextChargeEpoch: TimeInterval
}

struct CreditRecord: Codable, Equatable, Sendable {
    var id: UUID
    var brickID: UUID
    var title: String?
    var monthlyEquivalent: Double
    var berthKind: String
    var berthID: UUID
}

struct SinkRecord: Codable, Equatable, Sendable {
    var id: UUID
    var name: String
}

struct BallastRecord: Codable, Equatable, Sendable {
    var currencyCode: String
    var reminderEnabled: Bool
    var reminderHour: Int
    var onboardingComplete: Bool
}

enum BeamCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ ledger: BeamLedger) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(ledger)
    }

    static func decode(_ data: Data) throws -> BeamLedger {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return try decoder.decode(BeamLedger.self, from: data)
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
