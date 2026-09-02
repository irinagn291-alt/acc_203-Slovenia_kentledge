import SwiftUI
import UIKit

/// Role: Beam. Full-hit chrome. The label is the target; never the glyph alone.
struct HullChromeButton: View {
    var title: String
    var fillsWidth: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(HullStep.body.font)
                .foregroundStyle(HullSwatch.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.center)
                .frame(
                    maxWidth: fillsWidth ? .infinity : nil,
                    minHeight: HullSwatch.tap
                )
                .padding(.horizontal, HullSwatch.space(1))
                .background(HullSwatch.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: fillsWidth ? .infinity : nil)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
    }
}

/// Role: Beam. Seeded primary verb. Accent fill; the whole chrome is the target.
struct HullFillButton: View {
    var title: String
    var detail: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(HullStep.body.font.weight(.semibold))
                    .foregroundStyle(HullSwatch.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(detail)
                    .font(HullStep.caption.font)
                    .foregroundStyle(HullSwatch.ink.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, HullSwatch.space(2))
            .padding(.vertical, HullSwatch.space(1) + 4)
            .frame(minHeight: 56)
            .background(enabled ? HullSwatch.accent : HullSwatch.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityLabel("\(title). \(detail)")
    }
}

/// Role: Beam. Sheet header with a dismiss that always works.
struct HullSheetBar: View {
    var title: String
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: HullSwatch.space(1)) {
            Text(title)
                .hullText(.title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: HullSwatch.space(1))
            Button(action: onClose) {
                Text("Close")
                    .font(HullStep.body.font)
                    .foregroundStyle(HullSwatch.accent)
                    .frame(minWidth: HullSwatch.tap, minHeight: HullSwatch.tap)
                    .padding(.horizontal, HullSwatch.space(1))
                    .background(HullSwatch.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

/// Role: Beam. Full-page empty or error. CTA is bottom, full width.
struct HullVacancy: View {
    var image: String
    var headline: String
    var line: String
    var actionTitle: String
    var retry: Bool = false
    var action: () -> Void

    var body: some View {
        VStack(spacing: HullSwatch.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220, maxHeight: 220)
                .accessibilityHidden(true)
            Text(headline)
                .hullText(.title)
                .multilineTextAlignment(.center)
            Text(line)
                .hullText(.body)
                .foregroundStyle(HullSwatch.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button(action: action) {
                Text(actionTitle)
                    .font(HullStep.body.font)
                    .foregroundStyle(HullSwatch.ink)
                    .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                    .background(retry ? HullSwatch.accent : HullSwatch.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(HullSwatch.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HullSwatch.background)
    }
}

/// Role: Beam. System share sheet for month summary text.
struct HullShareSheet: UIViewControllerRepresentable {
    var text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
