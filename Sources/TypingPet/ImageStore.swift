import AppKit

enum PetImage: String, CaseIterable {
    case basic, left, right, pattern1, pattern2

    var displayName: String {
        switch self {
        case .basic: return "Idle image"
        case .left: return "Left-hand image"
        case .right: return "Right-hand image"
        case .pattern1: return "Space reaction"
        case .pattern2: return "Return reaction"
        }
    }
}

final class ImageStore {
    private(set) var images: [PetImage: NSImage] = [:]

    init() {
        reload()
    }

    func reload() {
        var loaded: [PetImage: NSImage] = [:]
        let customPaths = AppPreferences.shared.imagePaths
        for image in PetImage.allCases {
            if let customPath = customPaths[image.rawValue],
               let custom = NSImage(contentsOfFile: customPath) {
                loaded[image] = custom
                continue
            }
            if let url = bundledURL(for: image), let bundled = NSImage(contentsOf: url) {
                loaded[image] = bundled
            }
        }
        images = loaded
    }

    func reset(_ image: PetImage) {
        var paths = AppPreferences.shared.imagePaths
        paths.removeValue(forKey: image.rawValue)
        AppPreferences.shared.imagePaths = paths
        reload()
    }

    private func bundledURL(for image: PetImage) -> URL? {
        let fileName = image.rawValue + ".png"
        let candidates: [URL?] = [
            Bundle.main.resourceURL?.appendingPathComponent("images").appendingPathComponent(fileName),
            Bundle.main.resourceURL?.appendingPathComponent(fileName),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("images").appendingPathComponent(fileName),
            Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("images").appendingPathComponent(fileName)
        ]
        return candidates.compactMap { $0 }.first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
