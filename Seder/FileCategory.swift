import Foundation

enum FileCategory: String, CaseIterable {
    case images = "Images"
    case documents = "Documents"
    case videos = "Videos"
    case audio = "Audio"
    case installers = "Installers"
    case archives = "Archives"
    case code = "Code"
    case other = "Other"

    var folderName: String { rawValue }

    var extensions: Set<String> {
        switch self {
        case .images:
            return ["jpg", "jpeg", "png", "gif", "heic", "webp", "svg"]
        case .documents:
            return ["pdf", "doc", "docx", "txt", "rtf", "pages", "xls", "xlsx", "csv", "ppt", "pptx", "key", "numbers"]
        case .videos:
            return ["mp4", "mov", "avi", "mkv"]
        case .audio:
            return ["mp3", "wav", "m4a", "flac", "aiff"]
        case .installers:
            return ["dmg", "pkg"]
        case .archives:
            return ["zip", "rar", "7z", "tar", "gz"]
        case .code:
            return ["js", "ts", "py", "swift", "json", "html", "css", "sh"]
        case .other:
            return []
        }
    }

    /// Returns the category for a file based on its extension.
    static func category(for file: URL) -> FileCategory {
        let ext = file.pathExtension.lowercased()
        return allCases.first { $0.extensions.contains(ext) } ?? .other
    }
}
