import SwiftUI
import UIKit

/// Role: Beam. Dry-dock tokens. Hex lives only in the catalog; this is the only accessor.
/// background #14110E · surface #2A241C · ink #EDE6D6 · accent #C24A22 · muted #8B8574
enum HullSwatch {
    static var background: Color { Color("background") }
    static var surface: Color { Color("surface") }
    static var ink: Color { Color("ink") }
    static var accent: Color { Color("ktl_accent") }
    static var muted: Color { Color("muted") }

    static var backgroundUI: UIColor { named("background") }
    static var surfaceUI: UIColor { named("surface") }
    static var inkUI: UIColor { named("ink") }
    static var accentUI: UIColor { named("ktl_accent") }
    static var mutedUI: UIColor { named("muted") }

    static let space: CGFloat = 8
    static let tap: CGFloat = 44
    static let radius: CGFloat = 0
    static let motion: Animation = .easeInOut(duration: 0.28)

    static func space(_ units: Int) -> CGFloat {
        space * CGFloat(units)
    }

    private static func named(_ token: String) -> UIColor {
        UIColor(named: token) ?? .darkGray
    }
}

/// Role: Beam. Six SF Pro steps. Stencil is caption2 uppercase tracking; load is largeTitle tabular.
enum HullStep: CaseIterable {
    case load
    case title
    case body
    case stencil
    case caption
    case footnote

    var font: Font {
        switch self {
        case .load: .system(.largeTitle).weight(.semibold).monospacedDigit()
        case .title: .system(.title2).weight(.semibold)
        case .body: .system(.body)
        case .stencil: .system(.caption2).weight(.semibold)
        case .caption: .system(.caption)
        case .footnote: .system(.footnote)
        }
    }
}

extension View {
    func hullText(_ step: HullStep) -> some View {
        let base = font(step.font).foregroundStyle(HullSwatch.ink)
        switch step {
        case .stencil:
            return AnyView(
                base
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(HullSwatch.muted)
            )
        case .load:
            return AnyView(base.monospacedDigit())
        default:
            return AnyView(base)
        }
    }
}

/// Role: Beam. Display rounding only. Stored values stay full precision.
enum HullFigures {
    static func money(_ value: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func plain(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func day(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: calendar.startOfDay(for: date))
    }

    static func shortDay(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: calendar.startOfDay(for: date))
    }

    static func percent(_ share: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: share)) ?? "—"
    }

    static func hour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "j"
        let uses24 = formatter.dateFormat.contains("H")
        let clock = NumberFormatter()
        clock.numberStyle = .none
        let number = clock.string(from: NSNumber(value: uses24 ? hour : ((hour + 11) % 12) + 1)) ?? "—"
        if uses24 {
            return number
        }
        return hour < 12 ? "\(number) AM" : "\(number) PM"
    }
}
