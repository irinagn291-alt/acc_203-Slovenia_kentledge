import Foundation

/// Role: Sink. A named destination for a seated credit when the cut is not assigned to a keep.
struct NamedSink: Identifiable, Equatable, Sendable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
