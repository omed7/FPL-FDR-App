import SwiftUI

struct ContentView: View {
    @StateObject var manager = FPLManager()

    var body: some View {
        MainGridView(manager: manager)
    }
}
