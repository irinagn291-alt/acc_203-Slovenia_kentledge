import Foundation

/// Role: Beam. One slice of this month's load for charts.
struct LoadSlice: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var load: Double
    var share: Double
}

/// Role: Beam. Display math and share copy. Views never invent yearly totals.
enum BeamMath {
    static func periodLine(
        period: ChargePeriod?,
        nextChargeDay: Date,
        calendar: Calendar = .current
    ) -> String {
        let when = HullFigures.shortDay(nextChargeDay, calendar: calendar)
        guard let period else {
            return "Once · \(when)"
        }
        return "\(period.shortLabel) · \(when)"
    }

    static func loadSlices(from posts: [(id: UUID, name: String, load: Double)]) -> [LoadSlice] {
        let total = posts.reduce(0) { $0 + max(0, $1.load) }
        guard total > 0 else { return [] }
        return posts
            .filter { $0.load > 0 }
            .sorted { $0.load > $1.load }
            .map { post in
                LoadSlice(
                    id: post.id,
                    name: post.name,
                    load: post.load,
                    share: post.load / total
                )
            }
    }

    static func shareSummary(
        monthLoad: Double,
        yearLoad: Double,
        savedMonth: Double,
        chargeCount: Int,
        cutCount: Int,
        currencyCode: String
    ) -> String {
        let month = HullFigures.money(monthLoad, code: currencyCode)
        let year = HullFigures.money(yearLoad, code: currencyCode)
        let saved = HullFigures.money(savedMonth, code: currencyCode)
        let charges = chargeCount == 1 ? "1 charge" : "\(chargeCount) charges"
        let cuts = cutCount == 1 ? "1 cut" : "\(cutCount) cuts"
        return """
        Kentledge — this month
        Load \(month) (\(charges))
        About \(year) / year
        Saved by cutting \(saved) (\(cuts))
        """
    }
}
