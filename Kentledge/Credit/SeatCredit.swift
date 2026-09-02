import Foundation

/// Role: Credit. Freed monthlyEquivalent after a prepare. Nil berth means the cut is not committed.
struct SeatCredit: Identifiable, Equatable, Sendable {
    var id: UUID
    var brickID: UUID
    var title: String
    var monthlyEquivalent: Double
    var berth: CreditBerth?

    var isSeated: Bool {
        berth != nil
    }
}

/// Role: Credit. Where a prepared credit may land. A keep is a remaining brick; a sink is named.
enum CreditBerth: Equatable, Sendable, Hashable {
    case keep(UUID)
    case sink(UUID)
}
