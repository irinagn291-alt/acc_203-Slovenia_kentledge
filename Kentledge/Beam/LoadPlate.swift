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
    private let railLayer = CAShapeLayer()
    private let railCaption = CATextLayer()
    private let creditLayer = CAShapeLayer()
    private let creditCaption = CATextLayer()
    private var postButtons: [UUID: BrickPostButton] = [:]
    private var postRects: [UUID: CGRect] = [:]
    private var berthButtons: [UUID: UIButton] = [:]
    private var berthByKey: [UUID: CreditBerth] = [:]
    private var berthRects: [CreditBerth: CGRect] = [:]
    private var dragID: UUID?
    private var dragPoint: CGPoint?
    private var didLift = false

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
        rivetLayer.fillColor = HullSwatch.mutedUI.withAlphaComponent(0.35).cgColor
        rivetLayer.zPosition = 0
        layer.addSublayer(rivetLayer)
        railLayer.fillColor = HullSwatch.inkUI.cgColor
        railLayer.zPosition = 1
        layer.addSublayer(railLayer)
        railCaption.alignmentMode = .center
        railCaption.truncationMode = .end
        railCaption.zPosition = 2
        layer.addSublayer(railCaption)
        creditLayer.fillColor = HullSwatch.surfaceUI.cgColor
        creditLayer.strokeColor = HullSwatch.inkUI.cgColor
        creditLayer.lineWidth = 2
        creditLayer.zPosition = 20
        creditLayer.isHidden = true
        layer.addSublayer(creditLayer)
        creditCaption.alignmentMode = .center
        creditCaption.isWrapped = true
        creditCaption.truncationMode = .end
        creditCaption.zPosition = 21
        creditCaption.isHidden = true
        layer.addSublayer(creditCaption)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panCredit(_:)))
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        addGestureRecognizer(pan)
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
            if frameModel.pendingLoad != nil {
                dragID = frameModel.pendingBrickID
                dragPoint = point
                didLift = true
                setNeedsLayout()
                return
            }
            guard let id = hitPost(at: point), !isGhost(id) else { return }
            dragID = id
            dragPoint = point
            didLift = false
            onPrepare?(id)
        case .changed:
            guard dragID != nil else { return }
            dragPoint = point
            if !didLift, abs(gesture.translation(in: self).y) > HullSwatch.space(2) {
                didLift = true
            }
            setNeedsLayout()
        case .ended:
            defer { clearDrag() }
            guard frameModel.pendingLoad != nil else { return }
            if let berth = hitBerth(at: point) {
                onSeat?(berth)
            }
        case .cancelled:
            defer { clearDrag() }
            if frameModel.pendingLoad != nil {
                onAbandon?()
            }
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
        dragPoint = nil
        didLift = false
        setNeedsLayout()
    }

    private func rebuild() {
        let bounds = self.bounds
        guard bounds.width > 1, bounds.height > 1 else { return }
        let pad = HullSwatch.space(2)
        let railHeight = HullSwatch.space(4)
        let pending = frameModel.pendingLoad != nil
        let targets = pending ? frameModel.seatTargets : []
        let seatRow = HullSwatch.tap + HullSwatch.space(1)
        let bottomBand = pending
            ? CGFloat(max(targets.count, 1)) * seatRow + HullSwatch.space(1)
            : 0
        let fullPost = max(
            bounds.height - pad * 2 - railHeight - bottomBand,
            HullSwatch.tap * 4
        )
        let railY = pad + fullPost
        paintRivets(in: bounds)
        railLayer.path = UIBezierPath(
            rect: CGRect(x: pad, y: railY, width: max(bounds.width - pad * 2, 1), height: railHeight)
        ).cgPath
        paintCaption(
            railCaption,
            string: pending ? "SEAT THE FREED CREDIT" : "THIS MONTH'S CHARGES — JETTISON ONE",
            rect: CGRect(x: pad, y: railY, width: max(bounds.width - pad * 2, 1), height: railHeight),
            style: .caption2,
            color: HullSwatch.backgroundUI,
            wrapped: false
        )

        let posts = frameModel.posts
        let gap = HullSwatch.space(1)
        let inner = max(bounds.width - pad * 2, HullSwatch.tap)
        let slot = max(inner / CGFloat(max(posts.count, 1)), HullSwatch.tap)
        let maxLoad = max(posts.map(\.load).max() ?? 1, 0.01)
        let minPost = min(fullPost, max(HullSwatch.tap * 4, fullPost * 0.58))
        var nextPosts: [UUID: BrickPostButton] = [:]
        postRects = [:]
        for (index, post) in posts.enumerated() {
            let button = postButtons[post.id] ?? makePostButton()
            button.brickID = post.id
            let width = max(slot - gap, HullSwatch.tap)
            let x = pad + CGFloat(index) * slot + (slot - width) / 2
            let height = minPost + (fullPost - minPost) * CGFloat(post.load / maxLoad)
            let rect = CGRect(x: x, y: railY - height, width: width, height: height)
            postRects[post.id] = rect
            button.frame = rect
            button.apply(post: post, currencyCode: frameModel.currencyCode)
            let brickID = post.id
            button.accessibilityCustomActions = post.ghosted ? [] : [
                UIAccessibilityCustomAction(name: "Jettison") { [weak self] _ in
                    self?.onPrepare?(brickID)
                    return true
                }
            ]
            button.isHidden = false
            nextPosts[post.id] = button
            if button.superview == nil {
                addSubview(button)
            }
        }
        for (id, button) in postButtons where nextPosts[id] == nil {
            button.removeFromSuperview()
        }
        postButtons = nextPosts

        let bandY = railY + railHeight + HullSwatch.space(1)
        rebuildBerths(
            targets: targets,
            originY: bandY,
            width: bounds.width,
            pad: pad,
            row: seatRow
        )
        rebuildCredit(in: bounds)
        refreshAccess()
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
            let prefix = item.2 ? "Seat on sink" : "Seat on keep"
            styleFillButton(
                button,
                title: "\(prefix) \(item.1)",
                detail: nil,
                accent: !item.2
            )
            berthRects[item.0] = rect
            berthByKey[key] = item.0
            next[key] = button
            if button.superview == nil {
                addSubview(button)
            }
        }
        for (id, button) in berthButtons where next[id] == nil {
            button.removeFromSuperview()
        }
        berthButtons = next
    }

    private func rebuildCredit(in bounds: CGRect) {
        guard let pending = frameModel.pendingLoad else {
            creditLayer.isHidden = true
            creditCaption.isHidden = true
            creditLayer.path = nil
            return
        }
        creditLayer.isHidden = false
        creditCaption.isHidden = false
        let size = HullSwatch.space(10)
        let fallback: CGPoint
        if let ghost = frameModel.pendingBrickID, let rect = postRects[ghost] {
            fallback = CGPoint(x: rect.midX, y: max(rect.minY + size, size))
        } else {
            fallback = CGPoint(x: bounds.midX, y: bounds.height * 0.22)
        }
        let origin = dragPoint ?? fallback
        let rect = CGRect(x: origin.x - size / 2, y: origin.y - size / 2, width: size, height: size)
        creditLayer.path = UIBezierPath(ovalIn: rect).cgPath
        let money = HullFigures.money(pending, code: frameModel.currencyCode)
        paintCaption(
            creditCaption,
            string: "\(money)\nLOOSE",
            rect: rect.insetBy(dx: 6, dy: 10),
            style: .caption1,
            color: HullSwatch.inkUI
        )
    }

    private func makePostButton() -> BrickPostButton {
        let button = BrickPostButton(type: .custom)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panCredit(_:)))
        pan.maximumNumberOfTouches = 1
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
        styleFillButton(button, title: "Seat", detail: nil, accent: true)
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
        config.titleAlignment = .center
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
        if !creditLayer.isHidden, let pending = frameModel.pendingLoad {
            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityFrameInContainerSpace = creditLayer.path?.boundingBox ?? .zero
            element.accessibilityLabel = "Pending credit \(HullFigures.money(pending, code: frameModel.currencyCode))"
            element.accessibilityHint = "Seat it on a keep or a named sink"
            elements.append(element)
        }
        accessibilityElements = elements
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
        for label in [nameLabel, loadLabel, verbLabel] {
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.textColor = HullSwatch.inkUI
            label.numberOfLines = 2
            label.isUserInteractionEnabled = false
            addSubview(label)
        }
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        loadLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        verbLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        verbLabel.numberOfLines = 1
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
            verbLabel.text = "CUTTING"
            plateLayer.fillColor = HullSwatch.surfaceUI.withAlphaComponent(0.4).cgColor
            plateLayer.strokeColor = HullSwatch.mutedUI.cgColor
            plateLayer.lineDashPattern = [4, 3]
            plateLayer.lineWidth = 1.5
            isEnabled = false
        } else {
            verbLabel.text = "JETTISON"
            plateLayer.fillColor = HullSwatch.accentUI.cgColor
            plateLayer.strokeColor = HullSwatch.inkUI.cgColor
            plateLayer.lineDashPattern = nil
            plateLayer.lineWidth = post.mystery ? 3 : 1.5
            isEnabled = true
        }
        var label = "Charge \(post.name), monthly \(money)"
        if post.ghosted { label += ", ghosted" }
        if post.mystery { label += ", mystery charge" }
        accessibilityLabel = label
        accessibilityHint = post.ghosted
            ? "This brick is cut. Seat the freed credit."
            : "Jettison this charge, then seat the credit"
        accessibilityTraits = .button
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        plateLayer.frame = bounds
        let path = UIBezierPath(rect: bounds)
        rivets(in: bounds).forEach { path.append($0) }
        plateLayer.path = path.cgPath
        let inset = HullSwatch.space(1)
        let body = bounds.insetBy(dx: inset, dy: inset)
        let nameH = max(body.height * 0.26, HullSwatch.space(4))
        let loadH = max(body.height * 0.30, HullSwatch.space(4))
        let verbH = max(HullSwatch.space(4), UIFont.preferredFont(forTextStyle: .caption1).pointSize + 8)
        nameLabel.frame = CGRect(x: body.minX, y: body.minY, width: body.width, height: nameH)
        loadLabel.frame = CGRect(
            x: body.minX,
            y: body.minY + nameH,
            width: body.width,
            height: loadH
        )
        verbLabel.frame = CGRect(
            x: body.minX,
            y: body.maxY - verbH,
            width: body.width,
            height: verbH
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
