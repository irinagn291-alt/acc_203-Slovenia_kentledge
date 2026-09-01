import SwiftUI

/// Role: Beam. Host. The load beam never leaves; Insights and Settings arrive as sheets.
struct ContentView: View {
    @ObservedObject var watch: BeamWatch

    init(watch: BeamWatch) {
        self.watch = watch
    }

    init() {
        self.init(watch: .previewPopulated())
    }

    var body: some View {
        LedgerView(watch: watch)
    }
}

#Preview {
    ContentView()
}
