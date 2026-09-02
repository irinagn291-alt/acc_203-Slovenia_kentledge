import Charts
import SwiftUI

/// Role: Beam. Load mix + saved vs still paying. Pure presentation over BeamMath slices.
struct BeamChartPanel: View {
    var posts: [PlatePost]
    var monthLoad: Double
    var saved: Double
    var currencyCode: String

    private var slices: [LoadSlice] {
        BeamMath.loadSlices(from: posts.map { ($0.id, $0.name, $0.load) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(2)) {
            Text("Share of this month")
                .font(HullStep.caption.font.weight(.semibold))
                .foregroundStyle(HullSwatch.muted)
                .textCase(.uppercase)
                .tracking(0.6)
            if slices.isEmpty {
                Text("Add a charge to see the mix.")
                    .font(HullStep.body.font)
                    .foregroundStyle(HullSwatch.muted)
            } else {
                Chart(slices) { slice in
                    BarMark(
                        x: .value("Load", slice.load),
                        y: .value("Band", "Mix")
                    )
                    .foregroundStyle(by: .value("Charge", slice.name))
                }
                .chartForegroundStyleScale(range: barPalette)
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 44)
                .accessibilityLabel(mixLabel)

                ForEach(slices.prefix(5)) { slice in
                    HStack(alignment: .firstTextBaseline, spacing: HullSwatch.space(1)) {
                        Text(slice.name)
                            .font(HullStep.body.font)
                            .foregroundStyle(HullSwatch.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(HullFigures.percent(slice.share))
                            .font(HullStep.caption.font.monospacedDigit())
                            .foregroundStyle(HullSwatch.muted)
                        Text(HullFigures.money(slice.load, code: currencyCode))
                            .font(HullStep.body.font.monospacedDigit())
                            .foregroundStyle(HullSwatch.ink)
                            .frame(minWidth: 72, alignment: .trailing)
                    }
                    .frame(minHeight: 28)
                }
            }

            Text("Paying vs saved")
                .font(HullStep.caption.font.weight(.semibold))
                .foregroundStyle(HullSwatch.muted)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.top, HullSwatch.space(1))

            Chart {
                BarMark(
                    x: .value("Kind", "Still paying"),
                    y: .value("Amount", monthLoad)
                )
                .foregroundStyle(HullSwatch.accent)
                BarMark(
                    x: .value("Kind", "Saved"),
                    y: .value("Amount", saved)
                )
                .foregroundStyle(HullSwatch.ink.opacity(0.55))
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(HullStep.caption.font)
                                .foregroundStyle(HullSwatch.muted)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(HullSwatch.muted.opacity(0.35))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(HullFigures.money(amount, code: currencyCode))
                                .font(HullStep.footnote.font)
                                .foregroundStyle(HullSwatch.muted)
                        }
                    }
                }
            }
            .frame(height: 140)
            .accessibilityLabel(
                "Still paying \(HullFigures.money(monthLoad, code: currencyCode)), saved \(HullFigures.money(saved, code: currencyCode))"
            )
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HullSwatch.surface)
    }

    private var mixLabel: String {
        slices
            .map { "\($0.name) \(HullFigures.percent($0.share))" }
            .joined(separator: ", ")
    }

    private var barPalette: [Color] {
        [
            HullSwatch.accent,
            HullSwatch.ink.opacity(0.75),
            HullSwatch.muted,
            HullSwatch.accent.opacity(0.55),
            HullSwatch.ink.opacity(0.4),
        ]
    }
}
