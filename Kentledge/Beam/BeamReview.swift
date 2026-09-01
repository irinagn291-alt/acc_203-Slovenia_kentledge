import Foundation

/// Role: Beam. ReviewScreen today|log|goals. Read once, only after onboarding.
enum BeamReview: String, Equatable, Sendable {
    case today
    case log
    case goals
}

enum BeamLaunch {
    static func consume(
        arguments: [String],
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> BeamReview? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return BeamReview(rawValue: arguments[next])
    }

    static func bind(_ review: BeamReview, insights: inout Bool, settings: inout Bool) {
        switch review {
        case .today:
            insights = false
            settings = false
        case .log:
            insights = true
            settings = false
        case .goals:
            insights = false
            settings = true
        }
    }
}
