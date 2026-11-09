import Foundation

/// Checks the Downloads folder every 2 seconds and sorts new files
/// once their size has stopped changing (the download finished).
@MainActor
final class DownloadsWatcher {
    private let sorter: DownloadsSorter
    private let onSorted: ([FileMove]) -> Void

    private var knownFiles: Set<URL> = []
    private var pendingSizes: [URL: Int] = [:]
    private var task: Task<Void, Never>?

    init(sorter: DownloadsSorter, onSorted: @escaping ([FileMove]) -> Void) {
        self.sorter = sorter
        self.onSorted = onSorted
    }

    /// Starts watching. Files already in the folder are remembered and left alone.
    func start() {
        knownFiles = Set(sorter.sortableFiles())
        pendingSizes = [:]

        task?.cancel()
        task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                self.check()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func check() {
        let current = Set(sorter.sortableFiles())
        let newFiles = current.subtracting(knownFiles)

        var ready: [URL] = []
        var stillPending: [URL: Int] = [:]

        for file in newFiles {
            let size = sorter.size(of: file)
            if let previousSize = pendingSizes[file], previousSize == size, size > 0 {
                ready.append(file)              // same size twice in a row → finished
            } else {
                stillPending[file] = size       // check again in 2 seconds
            }
        }

        pendingSizes = stillPending
        knownFiles = current.subtracting(newFiles)

        guard !ready.isEmpty else { return }
        let moves = sorter.sort(ready)
        if !moves.isEmpty {
            onSorted(moves)
        }
    }
}
