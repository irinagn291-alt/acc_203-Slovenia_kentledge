import Foundation

/// Role: Beam. Preference keys. The snapshot key is the assigned UserDefaults contract.
enum BeamKey {
    static let snapshot = "ktl.beam.v1"
    static let backup = "ktl.beam.v1.backup"
    static let demo = "ktl.demo.v1"
}

/// Role: Beam. Recoverable load outcome. Never crash on a corrupt snapshot.
enum BeamWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Beam. The only persistence seam. Views observe the beam; they never touch UserDefaults or files.
protocol BeamStoring: Sendable {
    func load() async -> (beam: LoadBeam, warning: BeamWarning?)
    func beam() async -> LoadBeam
    func addBrick(_ brick: ChargeBrick) async throws -> LoadBeam
    func addSink(_ sink: NamedSink) async throws -> LoadBeam
    func setBallast(_ ballast: BeamBallast) async throws -> LoadBeam
    func prepare(brickID: UUID) async throws -> LoadBeam
    func seat(on berth: CreditBerth) async throws -> LoadBeam
    func abandon() async throws -> LoadBeam
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded() async throws -> LoadBeam?
}

/// Role: Beam. Memory is the source of truth. UserDefaults ktl.beam.v1 plus an Application Support file are projections.
actor BeamStore: BeamStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: LoadBeam = .vacant
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: BeamWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Kentledge", isDirectory: true)
    }

    func load() async -> (beam: LoadBeam, warning: BeamWarning?) {
        warning = nil
        latest = .vacant
        dirty = false
        let defaults = preferenceDefaults()
        if let data = defaults.data(forKey: BeamKey.snapshot), let beam = decode(data) {
            latest = beam
            return (latest, nil)
        }
        if let beam = decodeFile(fileURL) {
            latest = beam
            return (latest, nil)
        }
        if let data = defaults.data(forKey: BeamKey.backup), let beam = decode(data) {
            latest = beam
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let beam = decodeFile(backupURL) {
            latest = beam
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: BeamKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func beam() async -> LoadBeam {
        latest
    }

    func addBrick(_ brick: ChargeBrick) async throws -> LoadBeam {
        latest = try latest.adding(brick)
        try persistCommitted()
        return latest
    }

    func addSink(_ sink: NamedSink) async throws -> LoadBeam {
        latest = try latest.addingSink(sink)
        try persistCommitted()
        return latest
    }

    func setBallast(_ ballast: BeamBallast) async throws -> LoadBeam {
        latest = latest.settingBallast(ballast)
        try persistCommitted()
        return latest
    }

    func prepare(brickID: UUID) async throws -> LoadBeam {
        latest = try latest.preparing(brickID: brickID)
        return latest
    }

    func seat(on berth: CreditBerth) async throws -> LoadBeam {
        latest = try latest.seating(on: berth)
        try persistCommitted()
        return latest
    }

    func abandon() async throws -> LoadBeam {
        latest = try latest.abandoning()
        try persistCommitted()
        return latest
    }

    func note(_ beam: LoadBeam) async {
        latest = beam
        dirty = true
        scheduleFlush()
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .vacant
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: BeamKey.snapshot)
        defaults.removeObject(forKey: BeamKey.backup)
        defaults.removeObject(forKey: BeamKey.demo)
        defaults.synchronize()
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func seedDemoIfNeeded() async throws -> LoadBeam? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: BeamKey.demo) == nil else { return nil }
        latest = BeamSeed.beam()
        try persistCommitted()
        defaults.set(true, forKey: BeamKey.demo)
        defaults.synchronize()
        return latest
        #else
        return nil
        #endif
    }

    private func persistCommitted() throws {
        let ledger = BeamLedger.committed(from: latest)
        let data = try BeamCodec.encode(ledger)
        let defaults = preferenceDefaults()
        if let previous = defaults.data(forKey: BeamKey.snapshot) {
            defaults.set(previous, forKey: BeamKey.backup)
        }
        defaults.set(data, forKey: BeamKey.snapshot)
        defaults.synchronize()
        prepareDirectory()
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> LoadBeam? {
        guard let ledger = try? BeamCodec.decode(data) else { return nil }
        return ledger.asBeam()
    }

    private func decodeFile(_ url: URL) -> LoadBeam? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("beam.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("beam.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
