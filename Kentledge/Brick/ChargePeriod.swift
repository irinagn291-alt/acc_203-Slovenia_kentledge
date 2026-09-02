import Foundation

/// Role: Brick. Recurrence of a charge. `occurrencesPerMonth` is the family scale; weekly is 52/12.
enum ChargePeriod: String, Codable, Sendable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var occurrencesPerMonth: Double {
        switch self {
        case .weekly:
            52.0 / 12.0
        case .monthly:
            1
        case .quarterly:
            4.0 / 12.0
        case .yearly:
            1.0 / 12.0
        }
    }

    var shortLabel: String {
        switch self {
        case .weekly: "Week"
        case .monthly: "Month"
        case .quarterly: "Quarter"
        case .yearly: "Year"
        }
    }
}
