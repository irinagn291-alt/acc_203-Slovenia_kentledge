import XCTest
@testable import Kentledge

final class KentledgeTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: KentledgeApp.self), "KentledgeApp")
    }

    func test_ballastKeysAndContact() {
        XCTAssertEqual(BeamKey.snapshot, "ktl.beam.v1")
        XCTAssertEqual(BeamKey.demo, "ktl.demo.v2")
        XCTAssertEqual(BeamClient.userAgent, "Kentledge/1.0 (iOS; +https://kentledge-beam.pro)")
        XCTAssertEqual(ChargePeriod.weekly.occurrencesPerMonth, 52.0 / 12.0, accuracy: 1e-12)
    }
}
