import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isWatching: Bool = false
    @Published var sortedCount: Int = 0
    @Published var showWidget: Bool = true
    @Published var canUndo: Bool = false
}
