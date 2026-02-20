import SwiftUI
import Combine

class ScrollSyncManager: ObservableObject {
    @Published var offset: CGFloat = 0
}
