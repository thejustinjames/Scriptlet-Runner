import Foundation

struct ScanLocation: Identifiable, Hashable, Codable {
    let id: UUID
    var path: String
    var label: String
    var isEnabled: Bool
    var recursive: Bool

    init(
        id: UUID = UUID(),
        path: String,
        label: String? = nil,
        isEnabled: Bool = true,
        recursive: Bool = true
    ) {
        self.id = id
        self.path = path
        self.label = label ?? URL(fileURLWithPath: path).lastPathComponent
        self.isEnabled = isEnabled
        self.recursive = recursive
    }

    var url: URL {
        URL(fileURLWithPath: path)
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
