import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isWatching = false
    @Published var lastMessage = ""
    @Published private(set) var canUndo = false

    @Published var sortedCount: Int {
        didSet { UserDefaults.standard.set(sortedCount, forKey: "sortedCount") }
    }

    @Published var showWidget: Bool {
        didSet {
            UserDefaults.standard.set(showWidget, forKey: "showWidget")
            updateWidget()
        }
    }

    @Published var widgetOnTop: Bool {
        didSet {
            UserDefaults.standard.set(widgetOnTop, forKey: "widgetOnTop")
            widget.isOnTop = widgetOnTop
        }
    }

    @Published var widgetSize: WidgetSize {
        didSet {
            UserDefaults.standard.set(widgetSize.rawValue, forKey: "widgetSize")
            widget.size = widgetSize
        }
    }

    let sorter = DownloadsSorter()
    let widget = WidgetController()
    private var watcher: DownloadsWatcher?
    private var lastMoves: [FileMove] = [] {
        didSet { canUndo = !lastMoves.isEmpty }
    }

    init() {
        let defaults = UserDefaults.standard
        sortedCount = defaults.integer(forKey: "sortedCount")
        showWidget = defaults.object(forKey: "showWidget") as? Bool ?? true
        widgetOnTop = defaults.bool(forKey: "widgetOnTop")
        widgetSize = WidgetSize(rawValue: defaults.string(forKey: "widgetSize") ?? "") ?? .medium

        widget.isOnTop = widgetOnTop
        widget.size = widgetSize
        updateWidget()
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

    // MARK: - Widget

    private func updateWidget() {
        if showWidget {
            widget.show()
        } else {
            widget.hide()
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
