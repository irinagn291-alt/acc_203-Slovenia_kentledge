import XCTest
@testable import Kentledge

final class BeamStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "ktl.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesSeatedCut() async throws {
        let store = makeStore()
        let beam = BeamSeed.beam()
        for brick in beam.bricks {
            _ = try await store.addBrick(brick)
        }
        _ = try await store.addSink(beam.sinks[0])
        _ = try await store.setBallast(beam.ballast)
        _ = try await store.prepare(brickID: BeamSeed.weeklyID)
        _ = try await store.seat(on: .sink(BeamSeed.sinkID))

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertNil(loaded.beam.pendingCut)
        XCTAssertEqual(loaded.beam.bricks.map(\.id), [BeamSeed.monthlyID, BeamSeed.yearlyID])
        XCTAssertEqual(loaded.beam.seatedCredits.count, 1)
        XCTAssertEqual(loaded.beam.seatedCredits.first?.brickID, BeamSeed.weeklyID)
        XCTAssertEqual(loaded.beam.seatedCredits.first?.berth, .sink(BeamSeed.sinkID))
        XCTAssertEqual(loaded.beam.ballast.currencyCode, "USD")
        XCTAssertTrue(loaded.beam.ballast.onboardingComplete)
        XCTAssertEqual(
            loaded.beam.cancelSavings,
            9.99 * (52.0 / 12.0),
            accuracy: 1e-12
        )
    }

    func test_prepareStaysInMemory_seatAndAbandonWrite() async throws {
        let store = makeStore()
        _ = try await store.addBrick(BeamSeed.beam().bricks[0])
        _ = try await store.addSink(NamedSink(id: BeamSeed.sinkID, name: "Plate locker"))
        let afterAdd = defaults.data(forKey: BeamKey.snapshot)

        _ = try await store.prepare(brickID: BeamSeed.weeklyID)
        XCTAssertEqual(defaults.data(forKey: BeamKey.snapshot), afterAdd)
        let memory = await store.beam()
        XCTAssertEqual(memory.pendingCut?.brickID, BeamSeed.weeklyID)

        let coldAfterPrepare = await makeStore().load()
        XCTAssertNil(coldAfterPrepare.beam.pendingCut)
        XCTAssertEqual(coldAfterPrepare.beam.bricks.count, 1)
        XCTAssertTrue(coldAfterPrepare.beam.seatedCredits.isEmpty)

        _ = try await store.abandon()
        let coldAfterAbandon = await makeStore().load()
        XCTAssertNil(coldAfterAbandon.beam.pendingCut)
        XCTAssertEqual(coldAfterAbandon.beam.bricks.first?.id, BeamSeed.weeklyID)
        XCTAssertTrue(coldAfterAbandon.beam.seatedCredits.isEmpty)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = try await store.addBrick(BeamSeed.beam().bricks[1])
        if let good = defaults.data(forKey: BeamKey.snapshot) {
            defaults.set(good, forKey: BeamKey.backup)
        }
        let file = directory.appendingPathComponent("beam.json")
        let backup = directory.appendingPathComponent("beam.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: BeamKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.beam.bricks.first?.id, BeamSeed.monthlyID)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: BeamKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("beam.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.beam.bricks.isEmpty)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let ledger = BeamLedger.committed(from: BeamSeed.beam())
        let data = try BeamCodec.encode(ledger)
        let decoded = try BeamCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.bricks.count, 3)
        XCTAssertNil(Mirror(reflecting: decoded).children.first { $0.label == "pendingCut" })

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try BeamCodec.decode(future)) { error in
            XCTAssertEqual(error as? BeamCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try BeamCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? BeamCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = try await store.addBrick(BeamSeed.beam().bricks[0])
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.beam.bricks.isEmpty)
        XCTAssertNil(defaults.data(forKey: BeamKey.snapshot))
        XCTAssertNil(defaults.data(forKey: BeamKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async throws {
        let store = makeStore()
        let first = try await store.seedDemoIfNeeded()
        let second = try await store.seedDemoIfNeeded()
        XCTAssertNil(second)
        XCTAssertEqual(first?.bricks.count, 3)
        XCTAssertEqual(first?.sinks.first?.id, BeamSeed.sinkID)
        XCTAssertEqual(first?.ballast.onboardingComplete, true)
        XCTAssertTrue(defaults.bool(forKey: BeamKey.demo))
        XCTAssertNotNil(defaults.data(forKey: BeamKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("beam.json").path))
    }
    #endif

    private func makeStore() -> BeamStore {
        BeamStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }
}
