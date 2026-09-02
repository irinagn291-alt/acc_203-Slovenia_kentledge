import SwiftUI

/// Role: Sink. Named plates a pending credit may lock onto.
struct SinkRail: View {
    var sinks: [SinkBerth]
    var pending: Bool
    var onSeat: (UUID) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            Text("Savings buckets")
                .hullText(.stencil)
            if sinks.isEmpty {
                Text("No savings name yet. Add one to place freed money.")
                    .hullText(.caption)
                    .foregroundStyle(HullSwatch.muted)
            } else {
                ForEach(sinks) { sink in
                    Button {
                        onSeat(sink.id)
                    } label: {
                        Text("Put in \(sink.name)")
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
                    .accessibilityLabel("Put in \(sink.name)")
                }
            }
            Button(action: onAdd) {
                Text("New savings name")
                    .hullText(.body)
                    .foregroundStyle(HullSwatch.accent)
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                    .background(HullSwatch.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
