import CloudKit
import Foundation
import SwiftData

enum VoxiverseCloudKitReportSync {
    static let containerIdentifier = "iCloud.im.lystaria.Voxiverse"

    @MainActor
    static func refresh(into modelContext: ModelContext) async {
        do {
            let records = try await fetchAllReports()
            for record in records {
                try upsert(record, into: modelContext)
            }
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            print("Voxiverse report refresh failed: \(error)")
        }
    }

    private static func fetchAllReports() async throws -> [CKRecord] {
        let database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
        let inboxID = CKRecord.ID(recordName: "VoxiverseReportInbox")

        let inbox: CKRecord
        do {
            inbox = try await database.record(for: inboxID)
        } catch let error as CKError where error.code == .unknownItem {
            return []
        }

        let names = inbox["reportRecordNames"] as? [String] ?? []
        guard !names.isEmpty else { return [] }

        let ids = names.map { CKRecord.ID(recordName: $0) }
        let results = try await database.records(for: ids)
        return results.values.compactMap { result in
            if case .success(let record) = result { return record }
            return nil
        }
    }

    private static func fetchPage(
        database: CKDatabase,
        query: CKQuery?,
        cursor: CKQueryOperation.Cursor?
    ) async throws -> (records: [CKRecord], cursor: CKQueryOperation.Cursor?) {
        try await withCheckedThrowingContinuation { continuation in
            let operation = cursor.map(CKQueryOperation.init(cursor:)) ?? CKQueryOperation(query: query!)
            var pageRecords: [CKRecord] = []

            operation.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    pageRecords.append(record)
                }
            }

            operation.queryResultBlock = { result in
                switch result {
                case .success(let nextCursor):
                    continuation.resume(returning: (pageRecords, nextCursor))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            database.add(operation)
        }
    }

    @MainActor
    private static func upsert(_ record: CKRecord, into modelContext: ModelContext) throws {
        let reportID = string(record, "reportID", fallback: record.recordID.recordName)
        let descriptor = FetchDescriptor<VoxiverseReport>(
            predicate: #Predicate { $0.reportID == reportID }
        )
        let existing = try modelContext.fetch(descriptor).first
        let report = existing ?? makeReport(from: record)
        apply(record, to: report)

        if existing == nil {
            modelContext.insert(report)
        }

        replaceAttachments(from: record, for: report, in: modelContext)
    }

    private static func makeReport(from record: CKRecord) -> VoxiverseReport {
        VoxiverseReport(
            reportID: string(record, "reportID", fallback: record.recordID.recordName),
            appID: canonicalAppID(from: record),
            title: string(record, "title"),
            description: string(record, "descriptionText"),
            expectedBehavior: string(record, "expectedBehavior"),
            stepsToReproduce: steps(from: record),
            reportType: VoxiverseReportType(rawValue: string(record, "reportType")) ?? .bugReport,
            priority: VoxiversePriority(rawValue: string(record, "priority")) ?? .medium,
            status: VoxiverseReportStatus(rawValue: string(record, "status")) ?? .new,
            submittedDate: record["submittedAt"] as? Date ?? record.creationDate ?? .now,
            reporter: string(record, "reporterName", fallback: "Unknown"),
            deviceModel: string(record, "deviceModel"),
            iOSVersion: string(record, "iOSVersion"),
            appVersion: string(record, "appVersion"),
            buildNumber: string(record, "buildNumber"),
            screenName: string(record, "screenName"),
            internalNotes: string(record, "internalNotes"),
            attachments: []
        )
    }

    private static func apply(_ record: CKRecord, to report: VoxiverseReport) {
        report.appID = canonicalAppID(from: record)
        report.title = string(record, "title")
        report.reportDescription = string(record, "descriptionText")
        report.expectedBehavior = string(record, "expectedBehavior")
        report.stepsToReproduce = steps(from: record)
        report.reportTypeRawValue = string(record, "reportType", fallback: VoxiverseReportType.bugReport.rawValue)
        report.priorityRawValue = string(record, "priority", fallback: VoxiversePriority.medium.rawValue)
        report.statusRawValue = string(record, "status", fallback: VoxiverseReportStatus.new.rawValue)
        report.submittedDate = record["submittedAt"] as? Date ?? record.creationDate ?? report.submittedDate
        report.reporter = string(record, "reporterName", fallback: report.reporter.isEmpty ? "Unknown" : report.reporter)
        report.deviceModel = string(record, "deviceModel")
        report.iOSVersion = string(record, "iOSVersion")
        report.appVersion = string(record, "appVersion")
        report.buildNumber = string(record, "buildNumber")
        report.screenName = string(record, "screenName")
        report.internalNotes = string(record, "internalNotes")
    }

    private static func string(_ record: CKRecord, _ key: String, fallback: String = "") -> String {
        (record[key] as? String) ?? fallback
    }

    private static func steps(from record: CKRecord) -> [String] {
        if let array = record["stepsToReproduce"] as? [String] {
            return array.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        let raw = string(record, "stepsToReproduce")
        return raw
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func canonicalAppID(from record: CKRecord) -> String {
        let appName = string(record, "appName").trimmingCharacters(in: .whitespacesAndNewlines)
        if !appName.isEmpty {
            return appName.lowercased()
        }
        let bundle = string(record, "appID").lowercased()
        if bundle.contains("asterium") || bundle.contains("sterium") { return "sterium" }
        return bundle.isEmpty ? "unknown" : bundle
    }

    @MainActor
    private static func replaceAttachments(
        from record: CKRecord,
        for report: VoxiverseReport,
        in modelContext: ModelContext
    ) {
        for attachment in report.attachments ?? [] {
            modelContext.delete(attachment)
        }

        let attachments = attachmentModels(from: record)
        report.attachments = attachments

        for attachment in attachments {
            attachment.report = report
            modelContext.insert(attachment)
        }
    }

    private static func attachmentModels(from record: CKRecord) -> [VoxiverseReportAttachment] {
        (1...3).compactMap { index in
            guard let asset = record["attachment\(index)"] as? CKAsset else { return nil }
            let filename = asset.fileURL?.lastPathComponent ?? "Attachment \(index)"
            let localFileName = asset.fileURL.flatMap { fileURL in
                do {
                    return try persistAttachmentFile(
                        from: fileURL,
                        recordName: record.recordID.recordName,
                        index: index,
                        filename: filename
                    )
                } catch {
                    print("Voxiverse attachment copy failed: \(error)")
                    return nil
                }
            }

            return VoxiverseReportAttachment(
                id: "\(record.recordID.recordName)-attachment-\(index)",
                name: filename,
                detail: attachmentDetail(for: asset.fileURL),
                assetName: "imagesign",
                localFileName: localFileName
            )
        }
    }

    private static func persistAttachmentFile(
        from sourceURL: URL,
        recordName: String,
        index: Int,
        filename: String
    ) throws -> String {
        let directory = try VoxiverseReportAttachment.ensureAttachmentDirectory()
        let sourceExtension = sourceURL.pathExtension
        let filenameExtension = URL(fileURLWithPath: filename).pathExtension
        let fileExtension = filenameExtension.isEmpty ? sourceExtension : filenameExtension
        let stem = sanitizedFileStem("\(recordName)-attachment-\(index)")
        let localFileName = fileExtension.isEmpty ? stem : "\(stem).\(fileExtension)"
        let destinationURL = directory.appendingPathComponent(localFileName, isDirectory: false)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return localFileName
    }

    private static func sanitizedFileStem(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        return String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
    }

    private static func attachmentDetail(for fileURL: URL?) -> String {
        guard let fileURL else { return "CloudKit attachment" }
        let fileType = fileURL.pathExtension.isEmpty ? "File" : fileURL.pathExtension.uppercased()
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let size = attributes[.size] as? NSNumber
        else {
            return fileType
        }

        let sizeText = ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
        return "\(fileType) · \(sizeText)"
    }
}
