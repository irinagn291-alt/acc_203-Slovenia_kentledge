import Foundation

/// Role: Keep. A remaining uncut post. A pending credit may seat here; the cut then commits.
struct Keep: Identifiable, Equatable, Sendable {
    var id: UUID
    var brickID: UUID
    var name: String

    init(brick: ChargeBrick) {
        id = brick.id
        brickID = brick.id
        name = brick.name
    }
}
