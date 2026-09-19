import Foundation
import SwiftData

@Model
final class VoxiverseReportAttachment: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var detail: String = ""
    var assetName: String = "document"
    var localFileName: String?
    var report: VoxiverseReport?
    var featureRequest: VoxiverseFeatureRequest?

    static var attachmentDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoxiverseReportAttachments", isDirectory: true)
    }

    var localFileURL: URL? {
        guard let localFileName, !localFileName.isEmpty else { return nil }
        return Self.attachmentDirectory.appendingPathComponent(localFileName, isDirectory: false)
    }

    var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let stableIdentifier = Self.stableIdentifier(fromResolvedFilename: trimmedName) {
            return stableIdentifier
        }
        return trimmedName.isEmpty ? "Attachment" : trimmedName
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        detail: String,
        assetName: String,
        localFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.assetName = assetName
        self.localFileName = localFileName
    }

    static func ensureAttachmentDirectory() throws -> URL {
        let directory = attachmentDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func stableIdentifier(fromResolvedFilename filename: String) -> String? {
        let lastPathComponent = URL(fileURLWithPath: filename).lastPathComponent
        guard let dotIndex = lastPathComponent.firstIndex(of: ".") else { return nil }

        let prefix = String(lastPathComponent[..<dotIndex])
        let suffixStart = lastPathComponent.index(after: dotIndex)
        let suffix = String(lastPathComponent[suffixStart...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard UUID(uuidString: prefix) != nil, !suffix.isEmpty else { return nil }
        return suffix
    }
}
