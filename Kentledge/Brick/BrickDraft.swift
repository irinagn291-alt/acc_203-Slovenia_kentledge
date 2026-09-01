import SwiftUI

/// Role: Brick. In-place expand on the beam. No NavigationLink. No pushed detail.
struct BrickDraft: View {
    var brick: ChargeBrick?
    var currencyCode: String
    var onSave: (ChargeBrick) -> Void
    var onCancel: () -> Void

    @State private var name: String
    @State private var amountText: String
    @State private var period: ChargePeriod?
    @State private var nextDay: Date
    @FocusState private var focusAmount: Bool

    init(
        brick: ChargeBrick? = nil,
        currencyCode: String = "USD",
        onSave: @escaping (ChargeBrick) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        self.brick = brick
        self.currencyCode = currencyCode
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: brick?.name ?? "")
        _amountText = State(initialValue: brick.map { HullFigures.plain($0.amount) } ?? "")
        _period = State(initialValue: brick?.period ?? .monthly)
        _nextDay = State(initialValue: brick?.nextChargeDay ?? Calendar.current.startOfDay(for: Date()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HullSwatch.space(1)) {
            Text(brick == nil ? "Stand a brick" : "True the post")
                .hullText(.stencil)
            TextField("Name", text: $name)
                .hullText(.body)
                .padding(.horizontal, HullSwatch.space(1))
                .frame(minHeight: HullSwatch.tap)
                .background(HullSwatch.surface)
            TextField("Amount", text: $amountText)
                .hullText(.body)
                .keyboardType(.decimalPad)
                .focused($focusAmount)
                .padding(.horizontal, HullSwatch.space(1))
                .frame(minHeight: HullSwatch.tap)
                .background(HullSwatch.surface)
                .onChange(of: amountText, initial: false) { _, next in
                    amountText = Self.sanitize(next)
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { focusAmount = false }
                            .hullText(.body)
                            .foregroundStyle(HullSwatch.accent)
                    }
                }
            Picker("Period", selection: $period) {
                Text("None").tag(Optional<ChargePeriod>.none)
                ForEach(ChargePeriod.allCases, id: \.self) { item in
                    Text(Self.label(item)).tag(Optional(item))
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: HullSwatch.tap)
            DatePicker("Next charge", selection: $nextDay, displayedComponents: .date)
                .hullText(.body)
                .frame(minHeight: HullSwatch.tap)
            HStack(spacing: HullSwatch.space(1)) {
                HullChromeButton(title: "Hold", action: onCancel)
                Button(action: commit) {
                    Text("Stand")
                        .hullText(.body)
                        .foregroundStyle(HullSwatch.ink)
                        .frame(maxWidth: .infinity, minHeight: HullSwatch.tap)
                        .background(canStand ? HullSwatch.accent : HullSwatch.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canStand)
                .accessibilityLabel("Stand the brick")
            }
        }
        .padding(HullSwatch.space(2))
        .background(HullSwatch.surface)
        .onTapGesture { focusAmount = false }
    }

    private var canStand: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && parsedAmount.map { $0 > 0 } == true
    }

    private var parsedAmount: Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter.number(from: amountText)?.doubleValue
    }

    private func commit() {
        guard canStand, let amount = parsedAmount else { return }
        var next = brick ?? ChargeBrick(
            name: name,
            amount: amount,
            period: period,
            nextChargeDay: Calendar.current.startOfDay(for: nextDay)
        )
        next.name = name
        next.amount = amount
        next.period = period
        next.nextChargeDay = Calendar.current.startOfDay(for: nextDay)
        onSave(next)
    }

    private static func sanitize(_ raw: String) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        var kept = ""
        var sawSeparator = false
        for character in raw {
            if character.isNumber {
                kept.append(character)
            } else if String(character) == separator, !sawSeparator {
                kept.append(character)
                sawSeparator = true
            }
        }
        return kept
    }

    private static func label(_ period: ChargePeriod) -> String {
        switch period {
        case .weekly: "Week"
        case .monthly: "Month"
        case .quarterly: "Quarter"
        case .yearly: "Year"
        }
    }
}
