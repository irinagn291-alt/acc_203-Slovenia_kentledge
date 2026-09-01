import SwiftUI

/// Role: Keep. Remaining posts as seating targets. A ghost is never offered.
struct KeepRail: View {
    var keeps: [KeepPost]
    var pending: Bool
    var onSeat: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            Text("Keeps")
                .hullText(.stencil)
            if keeps.isEmpty {
                Text(pending ? "No remaining keep. Name a sink." : "Keeps appear after a prepare.")
                    .hullText(.caption)
                    .foregroundStyle(HullSwatch.muted)
            } else {
                ForEach(keeps) { keep in
                    Button {
                        onSeat(keep.brickID)
                    } label: {
                        Text("Seat on keep \(keep.name)")
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
                    .accessibilityLabel("Seat on keep \(keep.name)")
                }
            }
        }
    }
}
