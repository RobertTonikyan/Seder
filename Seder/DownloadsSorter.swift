import Foundation

/// One file that was moved: where it was and where it went.
struct FileMove {
    let from: URL
    let to: URL
}

@MainActor
final class DownloadsSorter {
    let folder: URL
    private let fileManager = FileManager.default

    /// Extensions browsers use while a download is still in progress.
    private let partialExtensions: Set<String> = ["crdownload", "download", "part", "partial", "tmp"]

    init(folder: URL = URL.downloadsDirectory) {
        self.folder = folder
    }

    /// Files directly inside the folder that are safe to sort:
    /// no folders, no hidden files, no unfinished downloads.
    func sortableFiles() -> [URL] {
        let items = (try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return items.filter { file in
            let isDirectory = (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory { return false }
            if partialExtensions.contains(file.pathExtension.lowercased()) { return false }
            return true
        }
    }

    /// Moves each file into its category folder. Returns the moves that succeeded.
    func sort(_ files: [URL]) -> [FileMove] {
        files.compactMap { try? move($0) }
    }

    /// Moves files back to where they were. Returns how many were restored.
    func undo(_ moves: [FileMove]) -> Int {
        var restored = 0
        for move in moves where fileManager.fileExists(atPath: move.to.path(percentEncoded: false)) {
            let target = uniqueURL(for: move.from.lastPathComponent, in: move.from.deletingLastPathComponent())
            if (try? fileManager.moveItem(at: move.to, to: target)) != nil {
                restored += 1
            }
        }
        return restored
    }

    /// File size in bytes (0 if unknown).
    func size(of file: URL) -> Int {
        (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    // MARK: - Private

    private func move(_ file: URL) throws -> FileMove {
        let category = FileCategory.category(for: file)
        let destinationFolder = folder.appendingPathComponent(category.folderName, isDirectory: true)
        try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)

        let destination = uniqueURL(for: file.lastPathComponent, in: destinationFolder)
        try fileManager.moveItem(at: file, to: destination)
        return FileMove(from: file, to: destination)
    }

    /// "report.pdf" → "report (1).pdf" → "report (2).pdf" … until the name is free.
    private func uniqueURL(for name: String, in folder: URL) -> URL {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = folder.appendingPathComponent(name)
        var number = 1

        while fileManager.fileExists(atPath: candidate.path(percentEncoded: false)) {
            let newName = ext.isEmpty ? "\(base) (\(number))" : "\(base) (\(number)).\(ext)"
            candidate = folder.appendingPathComponent(newName)
            number += 1
        }
        return candidate
    }
}
