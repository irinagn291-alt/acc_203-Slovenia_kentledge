import SwiftUI
import UIKit

/// Role: Beam. UIView load-beam. Charge posts are Buttons; pan detaches a brick and seats a credit.
final class LoadPlate: UIView {
    var onPrepare: ((UUID) -> Void)?
    var onSeat: ((CreditBerth) -> Void)?
    var onAbandon: (() -> Void)?
    var onExpand: ((UUID) -> Void)?

    private var frameModel = PlateFrame.vacant
    private let rivetLayer = CAShapeLayer()
    private let railBar = UIView()
    private let railLabel = UILabel()
    private let creditLayer = CAShapeLayer()
    private let creditCaption = CATextLayer()
    private let scroller = UIScrollView()
    private let stack = UIView()
    private let mixChart = LoadMixChartView()
    private var postButtons: [UUID: BrickPostButton] = [:]
    private var postRects: [UUID: CGRect] = [:]
    private var berthButtons: [UUID: UIButton] = [:]
    private var berthByKey: [UUID: CreditBerth] = [:]
    private var berthRects: [CreditBerth: CGRect] = [:]
    private var dragID: UUID?
    private var platePan: UIPanGestureRecognizer!

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        backgroundColor = HullSwatch.backgroundUI
        isAccessibilityElement = false
        clipsToBounds = true
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        rivetLayer.fillColor = HullSwatch.mutedUI.withAlphaComponent(0.22).cgColor
        rivetLayer.zPosition = 0
        layer.addSublayer(rivetLayer)

        railBar.backgroundColor = HullSwatch.inkUI
        railBar.isUserInteractionEnabled = false
        addSubview(railBar)

        railLabel.textAlignment = .center
        railLabel.numberOfLines = 1
        railLabel.adjustsFontForContentSizeCategory = true
        railLabel.adjustsFontSizeToFitWidth = true
        railLabel.minimumScaleFactor = 0.75
        railLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        railLabel.textColor = HullSwatch.backgroundUI
        railLabel.backgroundColor = .clear
        railLabel.isAccessibilityElement = true
        addSubview(railLabel)

        creditLayer.fillColor = HullSwatch.surfaceUI.cgColor
        creditLayer.strokeColor = HullSwatch.inkUI.cgColor
        creditLayer.lineWidth = 2
        creditLayer.zPosition = 40
        creditLayer.isHidden = true
        layer.addSublayer(creditLayer)
        creditCaption.alignmentMode = .center
        creditCaption.isWrapped = true
        creditCaption.truncationMode = .end
        creditCaption.zPosition = 41
        creditCaption.isHidden = true
        layer.addSublayer(creditCaption)

        scroller.alwaysBounceVertical = true
        scroller.showsVerticalScrollIndicator = true
        scroller.backgroundColor = .clear
        scroller.delaysContentTouches = false
        addSubview(scroller)
        stack.backgroundColor = .clear
        scroller.addSubview(stack)
        stack.addSubview(mixChart)

        platePan = UIPanGestureRecognizer(target: self, action: #selector(panCredit(_:)))
        platePan.maximumNumberOfTouches = 1
        platePan.minimumNumberOfTouches = 1
        platePan.delegate = self
        addGestureRecognizer(platePan)

        registerForTraitChanges(
            [UITraitDisplayScale.self, UITraitPreferredContentSizeCategory.self]
        ) { (plate: LoadPlate, _) in
            plate.setNeedsLayout()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width > 1 ? size.width : bounds.width,
            height: size.height > 1 ? size.height : bounds.height
        )
    }

    func apply(_ frame: PlateFrame) {
        frameModel = frame
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rebuild()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point)
    }

    @objc private func panCredit(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        switch gesture.state {
        case .began:
            // Pending seat uses the buttons only — no floating chip, no drag loop.
            guard frameModel.pendingLoad == nil else { return }
            guard let id = hitPost(at: point), !isGhost(id) else { return }
            dragID = id
            onPrepare?(id)
        case .ended:
            defer { clearDrag() }
            guard frameModel.pendingLoad != nil else { return }
            if let berth = hitBerth(at: point) {
                onSeat?(berth)
            }
        case .cancelled, .failed:
            clearDrag()
        default:
            break
        }
    }

    @objc private func postTapped(_ gesture: UITapGestureRecognizer) {
        guard frameModel.pendingLoad == nil else { return }
        guard let button = gesture.view as? BrickPostButton, let id = button.brickID, !isGhost(id) else { return }
        onPrepare?(id)
    }

    @objc private func postHeld(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, frameModel.pendingLoad == nil else { return }
        guard let button = gesture.view as? BrickPostButton, let id = button.brickID, !isGhost(id) else { return }
        onExpand?(id)
    }

    @objc private func seatTapped(_ sender: UIButton) {
        let key = sender.accessibilityIdentifier.flatMap(UUID.init(uuidString:))
        if let key, let berth = berthByKey[key] {
            onSeat?(berth)
        }
    }

    private func clearDrag() {
        dragID = nil
    }

    private func rebuild() {
        let bounds = self.bounds
        guard bounds.width > 1, bounds.height > 1 else { return }
        let pad = HullSwatch.space(2)
        let railHeight = HullSwatch.tap
        let pending = frameModel.pendingLoad != nil
        let targets = pending ? frameModel.seatTargets : []
        let gap = HullSwatch.space(1)
        let row: CGFloat = 72

        paintRivets(in: bounds)
        let railRect = CGRect(x: pad, y: pad, width: max(bounds.width - pad * 2, 1), height: railHeight)
        railBar.frame = railRect
        if let pending = frameModel.pendingLoad {
            let money = HullFigures.money(pending, code: frameModel.currencyCode)
            railLabel.text = "Freed \(money) — tap where it goes"
        } else {
            railLabel.text = "Tap a charge to cancel"
        }
        railLabel.accessibilityLabel = railLabel.text
        railLabel.frame = railRect.insetBy(dx: HullSwatch.space(1), dy: 0)
        // Keep rail above the scroll view so the caption never disappears under it.
        bringSubviewToFront(railBar)
        bringSubviewToFront(railLabel)

        let scrollerTop = pad + railHeight + gap
        scroller.frame = CGRect(
            x: 0,
            y: scrollerTop,
            width: bounds.width,
            height: max(bounds.height - scrollerTop, 1)
        )
        scroller.showsVerticalScrollIndicator = true
        insertSubview(scroller, belowSubview: railBar)

        let posts = frameModel.posts
        let contentWidth = max(bounds.width - pad * 2, HullSwatch.tap)
        var y: CGFloat = 0
        var nextPosts: [UUID: BrickPostButton] = [:]
        postRects = [:]

        for post in posts {
            let button = postButtons[post.id] ?? makePostButton()
            button.brickID = post.id
            let rectInStack = CGRect(x: pad, y: y, width: contentWidth, height: row)
            button.frame = rectInStack
            button.apply(post: post, currencyCode: frameModel.currencyCode)
            let brickID = post.id
            button.accessibilityCustomActions = post.ghosted ? [] : [
                UIAccessibilityCustomAction(name: "Cancel") { [weak self] _ in
                    self?.onPrepare?(brickID)
                    return true
                }
            ]
            button.isHidden = false
            nextPosts[post.id] = button
            if button.superview !== stack {
                button.removeFromSuperview()
                stack.addSubview(button)
            }
            postRects[post.id] = button.convert(button.bounds, to: self)
            y += row + gap
        }
        for (id, button) in postButtons where nextPosts[id] == nil {
            button.removeFromSuperview()
        }
        postButtons = nextPosts

        let berthStart = y + (posts.isEmpty ? 0 : 0)
        rebuildBerths(
            targets: targets,
            originY: berthStart,
            width: bounds.width,
            pad: pad,
            row: HullSwatch.tap + HullSwatch.space(1)
        )
        var cursor = targets.isEmpty
            ? berthStart
            : berthStart + CGFloat(targets.count) * (HullSwatch.tap + HullSwatch.space(1))

        if !pending, !posts.isEmpty, frameModel.monthLoad > 0 {
            cursor += gap
            let chartHeight = mixChart.preferredHeight(for: posts.count)
            mixChart.isHidden = false
            mixChart.frame = CGRect(x: pad, y: cursor, width: contentWidth, height: chartHeight)
            mixChart.apply(
                posts: posts,
                monthLoad: frameModel.monthLoad,
                saved: frameModel.cancelSavings,
                currencyCode: frameModel.currencyCode
            )
            cursor = mixChart.frame.maxY
        } else {
            mixChart.isHidden = true
            mixChart.frame = .zero
        }

        let contentHeight = cursor + pad
        stack.frame = CGRect(x: 0, y: 0, width: bounds.width, height: contentHeight)
        scroller.contentSize = CGSize(width: bounds.width, height: contentHeight)

        for (id, button) in postButtons {
            postRects[id] = button.convert(button.bounds, to: self)
        }
        for (key, button) in berthButtons {
            if let berth = berthByKey[key] {
                berthRects[berth] = button.convert(button.bounds, to: self)
            }
        }

        rebuildCredit(in: bounds)
        refreshAccess()
        bringSubviewToFront(railBar)
        bringSubviewToFront(railLabel)
    }

    private func paintRivets(in bounds: CGRect) {
        let path = UIBezierPath()
        let step = HullSwatch.space(4)
        let size: CGFloat = 3
        var y = HullSwatch.space(2)
        while y < bounds.height {
            var x = HullSwatch.space(2)
            while x < bounds.width {
                path.append(UIBezierPath(ovalIn: CGRect(x: x, y: y, width: size, height: size)))
                x += step
            }
            y += step
        }
        rivetLayer.path = path.cgPath
    }

    private func rebuildBerths(
        targets: [(CreditBerth, String, Bool)],
        originY: CGFloat,
        width: CGFloat,
        pad: CGFloat,
        row: CGFloat
    ) {
        var next: [UUID: UIButton] = [:]
        berthRects = [:]
        berthByKey = [:]
        for (index, item) in targets.enumerated() {
            let key = berthKey(item.0)
            let button = berthButtons[key] ?? makeBerthButton(key: key)
            let rect = CGRect(
                x: pad,
                y: originY + CGFloat(index) * row,
                width: max(width - pad * 2, HullSwatch.tap),
                height: HullSwatch.tap
            )
            button.frame = rect
            button.isHidden = false
            button.isEnabled = true
            let title = item.2
                ? "Put in \(item.1)"
                : "Keep \(item.1) instead"
            styleFillButton(
                button,
                title: title,
                detail: nil,
                accent: !item.2
            )
            if button.superview !== stack {
                button.removeFromSuperview()
                stack.addSubview(button)
            }
            berthRects[item.0] = button.convert(button.bounds, to: self)
            berthByKey[key] = item.0
            next[key] = button
        }
        for (id, button) in berthButtons where next[id] == nil {
            button.removeFromSuperview()
        }
        berthButtons = next
    }

    private func rebuildCredit(in bounds: CGRect) {
        // Freed amount lives on the rail + seat buttons. No floating chip (it blocked hits and froze layout).
        _ = bounds
        creditLayer.isHidden = true
        creditCaption.isHidden = true
        creditLayer.path = nil
    }

    private func makePostButton() -> BrickPostButton {
        let button = BrickPostButton(type: .custom)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panCredit(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(postTapped(_:)))
        tap.require(toFail: pan)
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(postHeld(_:)))
        hold.minimumPressDuration = 0.45
        button.addGestureRecognizer(pan)
        button.addGestureRecognizer(tap)
        button.addGestureRecognizer(hold)
        return button
    }

    private func makeBerthButton(key: UUID) -> UIButton {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = key.uuidString
        styleFillButton(button, title: "Put here", detail: nil, accent: true)
        button.addTarget(self, action: #selector(seatTapped(_:)), for: .touchUpInside)
        return button
    }

    private func styleFillButton(_ button: UIButton, title: String, detail: String?, accent: Bool) {
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(
            top: HullSwatch.space(1),
            leading: HullSwatch.space(1),
            bottom: HullSwatch.space(1),
            trailing: HullSwatch.space(1)
        )
        config.baseForegroundColor = HullSwatch.inkUI
        config.title = title
        config.subtitle = detail
        config.titleAlignment = .leading
        config.titleLineBreakMode = .byTruncatingTail
        config.subtitleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = UIFont.preferredFont(forTextStyle: .body)
            next.foregroundColor = HullSwatch.inkUI
            return next
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var next = incoming
            next.font = UIFont.preferredFont(forTextStyle: .caption1)
            next.foregroundColor = HullSwatch.inkUI
            return next
        }
        button.configuration = config
        button.backgroundColor = accent ? HullSwatch.accentUI : HullSwatch.surfaceUI
        button.layer.borderWidth = accent ? 0 : 1.5
        button.layer.borderColor = HullSwatch.inkUI.cgColor
        button.layer.cornerRadius = 0
        button.contentHorizontalAlignment = .leading
    }

    private func paintCaption(
        _ layer: CATextLayer,
        string: String,
        rect: CGRect,
        style: UIFont.TextStyle,
        color: UIColor,
        wrapped: Bool = true
    ) {
        let font = UIFont.preferredFont(forTextStyle: style)
        let size = max(12, font.pointSize)
        layer.string = string
        layer.font = font
        layer.fontSize = size
        layer.isWrapped = wrapped
        layer.contentsScale = window?.screen.scale ?? traitCollection.displayScale
        layer.foregroundColor = color.cgColor
        layer.frame = rect
    }

    private func hitPost(at point: CGPoint) -> UUID? {
        for (id, rect) in postRects where expand(rect).contains(point) {
            return id
        }
        return nil
    }

    private func hitBerth(at point: CGPoint) -> CreditBerth? {
        for (berth, rect) in berthRects where expand(rect).contains(point) {
            return berth
        }
        return nil
    }

    private func expand(_ rect: CGRect) -> CGRect {
        let padX = max(0, (HullSwatch.tap - rect.width) / 2)
        let padY = max(0, (HullSwatch.tap - rect.height) / 2)
        return rect.insetBy(dx: -padX, dy: -padY)
    }

    private func isGhost(_ id: UUID) -> Bool {
        frameModel.pendingBrickID == id
    }

    private func berthKey(_ berth: CreditBerth) -> UUID {
        switch berth {
        case .keep(let id), .sink(let id):
            return id
        }
    }

    private func refreshAccess() {
        var elements: [Any] = []
        for post in frameModel.posts {
            if let button = postButtons[post.id] {
                elements.append(button)
            }
        }
        for button in berthButtons.values {
            elements.append(button)
        }
        if let pending = frameModel.pendingLoad {
            railLabel.accessibilityLabel = "Freed \(HullFigures.money(pending, code: frameModel.currencyCode)). Tap Keep or Put in below."
        }
        accessibilityElements = elements
    }
}

extension LoadPlate: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        other.view is UIScrollView || other.view?.isDescendant(of: scroller) == true
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

/// Role: Beam. UIKit mix chart under the charge list. Fills the former empty void.
private final class LoadMixChartView: UIView {
    private let titleLabel = UILabel()
    private let barHost = UIView()
    private var rowLabels: [UILabel] = []
    private var barLayers: [CALayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = HullSwatch.surfaceUI
        titleLabel.text = "Share of this month"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1).withWeight(.semibold)
        titleLabel.textColor = HullSwatch.mutedUI
        titleLabel.adjustsFontForContentSizeCategory = true
        addSubview(titleLabel)
        barHost.backgroundColor = HullSwatch.backgroundUI
        addSubview(barHost)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func preferredHeight(for postCount: Int) -> CGFloat {
        let rows = min(max(postCount, 1), 5)
        return 24 + 20 + CGFloat(rows) * 28 + 16
    }

    func apply(
        posts: [PlatePost],
        monthLoad: Double,
        saved: Double,
        currencyCode: String
    ) {
        _ = saved
        let slices = BeamMath.loadSlices(from: posts.map { ($0.id, $0.name, $0.load) })
        let palette: [UIColor] = [
            HullSwatch.accentUI,
            HullSwatch.inkUI.withAlphaComponent(0.75),
            HullSwatch.mutedUI,
            HullSwatch.accentUI.withAlphaComponent(0.55),
            HullSwatch.inkUI.withAlphaComponent(0.4),
        ]

        barLayers.forEach { $0.removeFromSuperlayer() }
        barLayers = []
        rowLabels.forEach { $0.removeFromSuperview() }
        rowLabels = []

        let inset: CGFloat = 12
        let width = max(bounds.width - inset * 2, 1)
        titleLabel.frame = CGRect(x: inset, y: 10, width: width, height: 18)
        barHost.frame = CGRect(x: inset, y: 34, width: width, height: 16)

        var x: CGFloat = 0
        for (index, slice) in slices.enumerated() {
            let w = max(2, width * CGFloat(slice.share))
            let layer = CALayer()
            layer.backgroundColor = palette[index % palette.count].cgColor
            layer.frame = CGRect(x: x, y: 0, width: w, height: 16)
            barHost.layer.addSublayer(layer)
            barLayers.append(layer)
            x += w

            if index < 5 {
                let row = UILabel()
                row.adjustsFontForContentSizeCategory = true
                row.adjustsFontSizeToFitWidth = true
                row.minimumScaleFactor = 0.8
                row.numberOfLines = 1
                row.font = UIFont.preferredFont(forTextStyle: .footnote)
                row.textColor = HullSwatch.inkUI
                row.text = "\(slice.name)  \(HullFigures.percent(slice.share))  \(HullFigures.money(slice.load, code: currencyCode))"
                let rowY = barHost.frame.maxY + 8 + CGFloat(index) * 28
                row.frame = CGRect(x: inset, y: rowY, width: width, height: 24)
                addSubview(row)
                rowLabels.append(row)
            }
        }

        accessibilityLabel = slices
            .map { "\($0.name) \(HullFigures.percent($0.share))" }
            .joined(separator: ", ")
        isAccessibilityElement = true
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Frames are set in apply; re-apply if bounds changed with last posts via parent rebuild.
    }
}

/// Role: Beam. One charge post. The whole chrome is the Button.
private final class BrickPostButton: UIButton {
    var brickID: UUID?
    private let plateLayer = CAShapeLayer()
    private let nameLabel = UILabel()
    private let loadLabel = UILabel()
    private let verbLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isPointerInteractionEnabled = true
        layer.insertSublayer(plateLayer, at: 0)
        plateLayer.lineWidth = 1.5
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        nameLabel.textColor = HullSwatch.inkUI
        nameLabel.isUserInteractionEnabled = false
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.textAlignment = .left

        loadLabel.adjustsFontForContentSizeCategory = true
        loadLabel.adjustsFontSizeToFitWidth = true
        loadLabel.minimumScaleFactor = 0.8
        loadLabel.textColor = HullSwatch.inkUI
        loadLabel.isUserInteractionEnabled = false
        loadLabel.font = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize,
            weight: .semibold
        )
        loadLabel.numberOfLines = 1
        loadLabel.textAlignment = .right

        verbLabel.adjustsFontForContentSizeCategory = true
        verbLabel.adjustsFontSizeToFitWidth = true
        verbLabel.minimumScaleFactor = 0.8
        verbLabel.textColor = HullSwatch.inkUI.withAlphaComponent(0.85)
        verbLabel.isUserInteractionEnabled = false
        verbLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        verbLabel.numberOfLines = 1
        verbLabel.lineBreakMode = .byTruncatingTail
        verbLabel.textAlignment = .left

        addSubview(nameLabel)
        addSubview(loadLabel)
        addSubview(verbLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func apply(post: PlatePost, currencyCode: String) {
        let money = HullFigures.money(post.load, code: currencyCode)
        nameLabel.text = post.name
        loadLabel.text = money
        if post.ghosted {
            verbLabel.text = "Canceling — put the money somewhere"
            plateLayer.fillColor = HullSwatch.surfaceUI.withAlphaComponent(0.45).cgColor
            plateLayer.strokeColor = HullSwatch.mutedUI.cgColor
            plateLayer.lineDashPattern = [4, 3]
            plateLayer.lineWidth = 1.5
            isEnabled = false
        } else {
            verbLabel.text = post.mystery
                ? "\(post.detail) · check date"
                : post.detail
            plateLayer.fillColor = HullSwatch.accentUI.cgColor
            plateLayer.strokeColor = HullSwatch.inkUI.cgColor
            plateLayer.lineDashPattern = nil
            plateLayer.lineWidth = post.mystery ? 3 : 1.5
            isEnabled = true
        }
        var label = "\(post.name), \(money) a month, \(post.detail)"
        if post.ghosted { label += ", canceling" }
        if post.mystery { label += ", check the date" }
        accessibilityLabel = label
        accessibilityHint = post.ghosted
            ? "Put the freed money on another charge or a savings name."
            : "Cancel this charge, then put the freed money somewhere."
        accessibilityTraits = .button
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        plateLayer.frame = bounds
        let path = UIBezierPath(rect: bounds)
        rivets(in: bounds).forEach { path.append($0) }
        plateLayer.path = path.cgPath

        let insetX = HullSwatch.space(2)
        let insetY = HullSwatch.space(1) + 2
        let body = bounds.insetBy(dx: insetX, dy: insetY)
        let lineH = UIFont.preferredFont(forTextStyle: .headline).lineHeight
        let captionH = UIFont.preferredFont(forTextStyle: .caption1).lineHeight
        let loadW = min(max(body.width * 0.36, 72), 128)
        let nameW = max(body.width - loadW - HullSwatch.space(1), 48)

        nameLabel.frame = CGRect(x: body.minX, y: body.minY, width: nameW, height: lineH)
        loadLabel.frame = CGRect(x: body.maxX - loadW, y: body.minY, width: loadW, height: lineH)
        verbLabel.frame = CGRect(
            x: body.minX,
            y: min(body.minY + lineH + 4, body.maxY - captionH),
            width: body.width,
            height: captionH
        )
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let padX = max(0, (HullSwatch.tap - bounds.width) / 2)
        let padY = max(0, (HullSwatch.tap - bounds.height) / 2)
        return bounds.insetBy(dx: -padX, dy: -padY).contains(point)
    }

    private func rivets(in rect: CGRect) -> [UIBezierPath] {
        let inset: CGFloat = 6
        let size: CGFloat = 4
        let points = [
            CGPoint(x: rect.minX + inset, y: rect.minY + inset),
            CGPoint(x: rect.maxX - inset - size, y: rect.minY + inset),
            CGPoint(x: rect.minX + inset, y: rect.maxY - inset - size),
            CGPoint(x: rect.maxX - inset - size, y: rect.maxY - inset - size),
        ]
        return points.map { UIBezierPath(ovalIn: CGRect(origin: $0, size: CGSize(width: size, height: size))) }
    }
}

/// Role: Beam. SwiftUI host for the UIView plate. Chrome stays in SwiftUI.
struct LoadPlateHost: UIViewRepresentable {
    var frame: PlateFrame
    var onPrepare: (UUID) -> Void
    var onSeat: (CreditBerth) -> Void
    var onAbandon: () -> Void
    var onExpand: (UUID) -> Void

    func makeUIView(context: Context) -> LoadPlate {
        let plate = LoadPlate()
        plate.setContentHuggingPriority(.defaultLow, for: .horizontal)
        plate.setContentHuggingPriority(.defaultLow, for: .vertical)
        plate.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        plate.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return plate
    }

    func updateUIView(_ plate: LoadPlate, context: Context) {
        plate.onPrepare = onPrepare
        plate.onSeat = onSeat
        plate.onAbandon = onAbandon
        plate.onExpand = onExpand
        plate.apply(frame)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LoadPlate, context: Context) -> CGSize {
        CGSize(
            width: proposal.width ?? uiView.bounds.width,
            height: proposal.height ?? uiView.bounds.height
        )
    }
}
