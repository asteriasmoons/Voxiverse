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

    static var attachmentDirectory: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoxiverseReportAttachments", isDirectory: true)
    }

    var localFileURL: URL? {
        guard let localFileName, !localFileName.isEmpty else { return nil }
        return Self.attachmentDirectory.appendingPathComponent(localFileName, isDirectory: false)
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
}
