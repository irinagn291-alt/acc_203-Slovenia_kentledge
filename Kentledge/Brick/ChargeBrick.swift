import Foundation

/// Role: Brick. One subscription as a charge post. monthlyEquivalent is derived; it is never stored.
struct ChargeBrick: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String
    var amount: Double
    var period: ChargePeriod?
    var nextChargeDay: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        period: ChargePeriod?,
        nextChargeDay: Date
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.period = period
        self.nextChargeDay = nextChargeDay
    }

    var monthlyEquivalent: Double {
        amount * (period?.occurrencesPerMonth ?? 0)
    }

    /// Forecast posts land only in a month that actually contains a charge — never a smeared year.
    func appearsInChargeMonth(_ date: Date, calendar: Calendar) -> Bool {
        let origin = calendar.startOfDay(for: nextChargeDay)
        guard let viewStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return false
        }
        switch period {
        case .none:
            return calendar.isDate(origin, equalTo: viewStart, toGranularity: .month)
        case .weekly:
            return weeklyHit(in: viewStart, origin: origin, calendar: calendar)
        case .monthly:
            guard let firstMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: origin)) else {
                return false
            }
            return viewStart >= firstMonth
        case .quarterly:
            return alignedMonths(from: origin, to: viewStart, every: 3, calendar: calendar)
        case .yearly:
            return alignedMonths(from: origin, to: viewStart, every: 12, calendar: calendar)
        }
    }

    private func weeklyHit(in monthStart: Date, origin: Date, calendar: Calendar) -> Bool {
        guard let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return false
        }
        let begin = max(monthStart, origin)
        if begin > monthEnd {
            return false
        }
        let gap = calendar.dateComponents([.day], from: origin, to: begin).day ?? 0
        let wait = gap <= 0 ? 0 : (7 - (gap % 7)) % 7
        guard let hit = calendar.date(byAdding: .day, value: wait, to: begin) else {
            return false
        }
        return hit <= monthEnd
    }

    private func alignedMonths(from origin: Date, to viewStart: Date, every stride: Int, calendar: Calendar) -> Bool {
        guard let firstMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: origin)) else {
            return false
        }
        if viewStart < firstMonth {
            return false
        }
        let delta = calendar.dateComponents([.month], from: firstMonth, to: viewStart).month ?? -1
        return delta >= 0 && delta % stride == 0
    }
}
