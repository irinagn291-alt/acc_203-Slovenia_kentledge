import SwiftUI
@testable import Kentledge

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("ledger", AnyView(LedgerView())),
            ("insights", AnyView(InsightsView())),
            ("cuts", AnyView(CutsView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
