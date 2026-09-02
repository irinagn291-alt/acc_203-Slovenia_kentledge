import SwiftUI

/// Role: Keep. Remaining posts as seating targets. A ghost is never offered.
struct KeepRail: View {
    var keeps: [KeepPost]
    var pending: Bool
    var onSeat: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            Text("Keep paying")
                .hullText(.stencil)
            if keeps.isEmpty {
                Text(pending ? "No other charge left. Add a savings name." : "Other charges show up after you start a cancel.")
                    .hullText(.caption)
                    .foregroundStyle(HullSwatch.muted)
            } else {
                ForEach(keeps) { keep in
                    Button {
                        onSeat(keep.brickID)
                    } label: {
                        Text("Keep \(keep.name)")
                            .hullText(.body)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, HullSwatch.space(1))
                            .frame(minHeight: HullSwatch.tap)
                            .background(pending ? HullSwatch.accent : HullSwatch.surface)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!pending)
                    .accessibilityLabel("Keep \(keep.name)")
                }
            }
        }
    }
}
