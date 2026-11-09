import Foundation
import CoreServices
import AppKit
import Combine

/// One file that hasn't been used for a while.
struct UnusedFile: Identifiable {
    let url: URL
    let name: String
    let location: String
    let lastUsed: Date
    let size: Int64

    var id: URL { url }
}

/// Finds files in Downloads and on the Desktop that you haven't opened in a while.
@MainActor
final class UnusedFilesModel: ObservableObject {
    @Published private(set) var files: [UnusedFile] = []
    @Published private(set) var message = ""
    @Published var selection: Set<URL> = []
    @Published var days: Int = 30 {
        didSet { scan() }
    }

    private let roots: [URL] = [URL.downloadsDirectory, URL.desktopDirectory]
    private let fileManager = FileManager.default

    /// Total size of the selected files, e.g. "1.2 GB".
    var selectedSizeText: String {
        let total = files
            .filter { selection.contains($0.url) }
            .reduce(Int64(0)) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    // MARK: - Scan

    func scan() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var result: [UnusedFile] = []

        for root in roots {
            for folder in foldersToScan(in: root) {
                for file in listFiles(in: folder) {
                    let lastUsed = lastUsedDate(of: file)
                    guard lastUsed < cutoff else { continue }

                    result.append(UnusedFile(
                        url: file,
                        name: file.lastPathComponent,
                        location: location(of: file),
                        lastUsed: lastUsed,
                        size: size(of: file)
                    ))
                }
            }
        }

        files = result.sorted { $0.lastUsed < $1.lastUsed }
        selection = selection.intersection(Set(files.map(\.url)))
        message = files.isEmpty
            ? "No unused files – nice and tidy!"
            : "\(files.count) files not opened in \(days) days"
    }

    // MARK: - Actions

    /// Moves the selected files to the Trash (never deletes permanently).
    func moveSelectedToTrash() {
        var trashed = 0
        for url in selection {
            if (try? fileManager.trashItem(at: url, resultingItemURL: nil)) != nil {
                trashed += 1
            }
        }
        selection = []
        scan()
        message = "Moved \(trashed) file(s) to the Trash"
    }

    /// Shows the selected files in Finder.
    func revealSelected() {
        NSWorkspace.shared.activateFileViewerSelecting(Array(selection))
    }

    // MARK: - Private

    /// The folder itself plus Seder's category folders inside it (Images, Documents…).
    private func foldersToScan(in root: URL) -> [URL] {
        let categoryFolders = FileCategory.allCases
            .map { root.appendingPathComponent($0.folderName, isDirectory: true) }
            .filter { folder in
                var isDirectory: ObjCBool = false
                return fileManager.fileExists(atPath: folder.path(percentEncoded: false), isDirectory: &isDirectory)
                    && isDirectory.boolValue
            }
        return [root] + categoryFolders
    }

    /// Files directly inside a folder (no subfolders, no hidden files).
    private func listFiles(in folder: URL) -> [URL] {
        let items = (try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return items.filter { file in
            let isDirectory = (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            return !isDirectory
        }
    }

    /// When the file was last opened, according to Spotlight.
    /// If Spotlight doesn't know, use the older of "created" and "last changed".
    private func lastUsedDate(of file: URL) -> Date {
        if let item = MDItemCreateWithURL(kCFAllocatorDefault, file as CFURL),
           let date = MDItemCopyAttribute(item, kMDItemLastUsedDate) as? Date {
            return date
        }

        let values = try? file.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
        let dates = [values?.creationDate, values?.contentModificationDate].compactMap { $0 }
        return dates.min() ?? Date()
    }

    /// "~/Downloads/Documents"
    private func location(of file: URL) -> String {
        let folderPath = file.deletingLastPathComponent().path(percentEncoded: false)
        let homePath = fileManager.homeDirectoryForCurrentUser.path(percentEncoded: false)
        let trimmed = folderPath.hasSuffix("/") ? String(folderPath.dropLast()) : folderPath
        let home = homePath.hasSuffix("/") ? String(homePath.dropLast()) : homePath
        return trimmed.replacingOccurrences(of: home, with: "~")
    }

    private func size(of file: URL) -> Int64 {
        Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }
}
