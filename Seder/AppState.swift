import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isWatching = false
    @Published var showWidget = true
    @Published var lastMessage = ""
    @Published private(set) var canUndo = false
    @Published var sortedCount: Int {
        didSet { UserDefaults.standard.set(sortedCount, forKey: "sortedCount") }
    }

    let sorter = DownloadsSorter()
    private var watcher: DownloadsWatcher?
    private var lastMoves: [FileMove] = [] {
        didSet { canUndo = !lastMoves.isEmpty }
    }

    init() {
        sortedCount = UserDefaults.standard.integer(forKey: "sortedCount")
        startWatching()
    }

    // MARK: - Watching

    func startWatching() {
        let watcher = DownloadsWatcher(sorter: sorter) { [weak self] moves in
            self?.didSort(moves)
        }
        watcher.start()
        self.watcher = watcher
        isWatching = true
    }

    func stopWatching() {
        watcher?.stop()
        watcher = nil
        isWatching = false
    }

    // MARK: - Actions

    /// Sorts everything currently in Downloads (old files too).
    func sortNow() {
        let moves = sorter.sort(sorter.sortableFiles())
        didSort(moves)
    }

    /// Moves the last sorted batch back to Downloads.
    func undoLastSort() {
        let restored = sorter.undo(lastMoves)
        sortedCount = max(0, sortedCount - restored)
        lastMoves = []
        lastMessage = "Restored \(restored) file(s)"

        // Re-snapshot so the restored files are not sorted again right away.
        if isWatching {
            watcher?.start()
        }
    }

    // MARK: - Private

    private func didSort(_ moves: [FileMove]) {
        guard !moves.isEmpty else {
            lastMessage = "Nothing to sort"
            return
        }

        lastMoves = moves
        sortedCount += moves.count

        if moves.count == 1, let move = moves.first {
            let folderName = move.to.deletingLastPathComponent().lastPathComponent
            lastMessage = "\(move.to.lastPathComponent) → \(folderName)"
        } else {
            lastMessage = "Sorted \(moves.count) files"
        }
    }
}
