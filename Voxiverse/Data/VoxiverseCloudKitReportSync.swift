import CloudKit
import Foundation
import SwiftData

enum VoxiverseCloudKitReportSync {
    static let containerIdentifier = "iCloud.im.lystaria.Voxiverse"

    enum StatusUpdateError: LocalizedError {
        case invalidStatus

        var errorDescription: String? {
            switch self {
            case .invalidStatus:
                return "That status is not valid for this report type."
            }
        }
    }

    @MainActor
    static func refresh(into modelContext: ModelContext) async {
        do {
            let records = try await fetchAllReports()
            for record in records {
                if VoxiverseReportType(rawValue: string(record, "reportType")) == .featureRequest {
                    try upsertFeatureRequest(record, into: modelContext)
                } else {
                    try upsert(record, into: modelContext)
                }
            }
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            print("Voxiverse report refresh failed: \(error)")
        }
    }

    @MainActor
    static func updateStatus(
        _ newStatus: VoxiverseReportStatus,
        for report: VoxiverseReport,
        in modelContext: ModelContext
    ) async throws {
        guard report.allowedStatuses.contains(newStatus) else {
            throw StatusUpdateError.invalidStatus
        }

        let oldStatus = report.status
        guard oldStatus != newStatus else { return }

        report.status = newStatus
        do {
            try modelContext.save()
        } catch {
            report.status = oldStatus
            throw error
        }

        do {
            let database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
            let recordID = CKRecord.ID(recordName: report.reportID)
            let record = try await database.record(for: recordID)
            record["status"] = newStatus.rawValue as CKRecordValue
            _ = try await database.save(record)
        } catch {
            report.status = oldStatus
            try? modelContext.save()
            throw error
        }

        let appName = report.app?.name ?? "Unknown App"
        do {
            try VoxiverseActivityStore.recordStatusChange(
                for: report,
                from: oldStatus,
                to: newStatus,
                appName: appName,
                dedupeKey: "local-status-\(report.reportID)-\(UUID().uuidString)",
                in: modelContext
            )
            try modelContext.save()
        } catch {
            print("Voxiverse status activity save failed: \(error)")
        }
    }

    @MainActor
    static func updateStatus(
        _ newStatus: VoxiverseFeatureRequestStatus,
        for request: VoxiverseFeatureRequest,
        in modelContext: ModelContext
    ) async throws {
        guard request.allowedStatuses.contains(newStatus) else {
            throw StatusUpdateError.invalidStatus
        }

        let oldStatus = request.status
        guard oldStatus != newStatus else { return }

        request.status = newStatus
        request.updatedDate = Date.now
        do {
            try modelContext.save()
        } catch {
            request.status = oldStatus
            throw error
        }

        do {
            let database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
            let recordID = CKRecord.ID(recordName: request.id)
            let record = try await database.record(for: recordID)
            record["status"] = newStatus.rawValue as CKRecordValue
            record["updatedAt"] = Date.now as CKRecordValue
            _ = try await database.save(record)
        } catch {
            request.status = oldStatus
            try? modelContext.save()
            throw error
        }

        let appName = request.app?.name ?? "Unknown App"
        do {
            try VoxiverseActivityStore.recordStatusChange(
                for: request,
                from: oldStatus,
                to: newStatus,
                appName: appName,
                dedupeKey: "local-request-status-\(request.id)-\(UUID().uuidString)",
                in: modelContext
            )
            try modelContext.save()
        } catch {
            print("Voxiverse feature request status activity save failed: \(error)")
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
        let oldStatus = existing?.status
        apply(record, to: report)
        report.app = try managedApp(for: report.appID, in: modelContext)

        if existing == nil {
            modelContext.insert(report)
            try VoxiverseActivityStore.recordReceived(
                for: report,
                appName: report.app?.name ?? string(record, "appName", fallback: "Unknown App"),
                in: modelContext
            )
        } else if let oldStatus, oldStatus != report.status {
            try VoxiverseActivityStore.recordStatusChange(
                for: report,
                from: oldStatus,
                to: report.status,
                appName: report.app?.name ?? string(record, "appName", fallback: "Unknown App"),
                dedupeKey: "remote-status-\(report.reportID)-\(record.modificationDate?.timeIntervalSince1970 ?? 0)-\(report.status.rawValue)",
                in: modelContext
            )
        }

        replaceAttachments(from: record, for: report, in: modelContext)
    }

    @MainActor
    private static func upsertFeatureRequest(_ record: CKRecord, into modelContext: ModelContext) throws {
        let requestID = string(
            record,
            "requestID",
            fallback: string(record, "reportID", fallback: record.recordID.recordName)
        )
        let descriptor = FetchDescriptor<VoxiverseFeatureRequest>(
            predicate: #Predicate { $0.id == requestID }
        )
        let existing = try modelContext.fetch(descriptor).first
        let request = existing ?? makeFeatureRequest(from: record, requestID: requestID)
        let oldStatus = existing?.status
        apply(record, to: request)
        request.app = try managedApp(for: request.appID, in: modelContext)

        let legacyReportDescriptor = FetchDescriptor<VoxiverseReport>(
            predicate: #Predicate { $0.reportID == requestID }
        )
        for legacyReport in try modelContext.fetch(legacyReportDescriptor) {
            modelContext.delete(legacyReport)
        }

        if existing == nil {
            modelContext.insert(request)
            try VoxiverseActivityStore.recordReceived(
                for: request,
                appName: request.app?.name ?? string(record, "appName", fallback: "Unknown App"),
                in: modelContext
            )
        } else if let oldStatus, oldStatus != request.status {
            try VoxiverseActivityStore.recordStatusChange(
                for: request,
                from: oldStatus,
                to: request.status,
                appName: request.app?.name ?? string(record, "appName", fallback: "Unknown App"),
                dedupeKey: "remote-request-status-\(request.id)-\(record.modificationDate?.timeIntervalSince1970 ?? 0)-\(request.status.rawValue)",
                in: modelContext
            )
        }

        replaceAttachments(from: record, for: request, in: modelContext)
    }

    private static func makeReport(from record: CKRecord) -> VoxiverseReport {
        VoxiverseReport(
            reportID: string(record, "reportID", fallback: record.recordID.recordName),
            appID: canonicalAppID(from: record),
            title: string(record, "title"),
            description: string(record, "descriptionText"),
            category: string(record, "category"),
            expectedBehavior: string(record, "expectedBehavior"),
            stepsToReproduce: steps(from: record),
            reportType: VoxiverseReportType(rawValue: string(record, "reportType")) ?? .bugReport,
            priority: VoxiversePriority(rawValue: string(record, "priority")) ?? .medium,
            status: VoxiverseReportStatus(rawValue: string(record, "status")) ?? .new,
            submittedDate: record["submittedAt"] as? Date ?? record.creationDate ?? Date.now,
            reporter: reporterName(from: record),
            deviceModel: string(record, "deviceModel"),
            iOSVersion: string(record, "iOSVersion"),
            appVersion: string(record, "appVersion"),
            buildNumber: string(record, "buildNumber"),
            screenName: string(record, "screenName"),
            internalNotes: string(record, "internalNotes"),
            overallExperience: string(record, "overallExperience"),
            testedWhat: string(record, "testedWhat", fallback: string(record, "descriptionText")),
            workedWell: string(record, "workedWell"),
            couldBeBetter: string(record, "couldBeBetter"),
            anythingUnexpected: string(record, "anythingUnexpected"),
            attachments: []
        )
    }

    private static func makeFeatureRequest(from record: CKRecord, requestID: String) -> VoxiverseFeatureRequest {
        let createdDate = record["createdAt"] as? Date
            ?? record["submittedAt"] as? Date
            ?? record.creationDate
            ?? Date.now
        return VoxiverseFeatureRequest(
            id: requestID,
            appID: canonicalAppID(from: record),
            title: string(record, "title"),
            description: string(record, "descriptionText"),
            category: string(record, "category"),
            featureType: string(record, "featureType"),
            featureImportance: string(record, "importance"),
            intendedAudience: string(record, "intendedAudience"),
            featureDescription: string(record, "featureDescription"),
            imaginedWorkflow: string(record, "imaginedWorkflow"),
            desiredLocation: string(record, "desiredLocation"),
            relatedExistingFeature: string(record, "relatedExistingFeature"),
            problemAddressed: string(record, "problemAddressed"),
            desiredResult: string(record, "desiredResult"),
            requiresSavedData: string(record, "requiresSavedData"),
            needsNotifications: string(record, "needsNotifications"),
            needsSharing: string(record, "needsSharing"),
            needsAI: string(record, "needsAI"),
            additionalDetails: string(record, "additionalDetails"),
            deviceModel: string(record, "deviceModel"),
            iOSVersion: string(record, "iOSVersion"),
            appVersion: string(record, "appVersion"),
            buildNumber: string(record, "buildNumber"),
            bundleIdentifier: string(record, "bundleIdentifier"),
            screenName: string(record, "screenName"),
            locale: string(record, "locale"),
            timeZone: string(record, "timeZone"),
            status: VoxiverseFeatureRequestStatus(rawValue: string(record, "status")) ?? .new,
            requestCount: integer(record, "requestCount"),
            createdDate: createdDate,
            updatedDate: record["updatedAt"] as? Date ?? record["submittedAt"] as? Date ?? createdDate,
            submitter: reporterName(from: record),
            internalNotes: string(record, "internalNotes")
        )
    }

    private static func apply(_ record: CKRecord, to report: VoxiverseReport) {
        report.appID = canonicalAppID(from: record)
        report.title = string(record, "title")
        report.reportDescription = string(record, "descriptionText")
        report.category = string(record, "category")
        report.expectedBehavior = string(record, "expectedBehavior")
        report.stepsToReproduce = steps(from: record)
        report.reportTypeRawValue = string(record, "reportType", fallback: VoxiverseReportType.bugReport.rawValue)
        report.priorityRawValue = string(record, "priority", fallback: VoxiversePriority.medium.rawValue)
        report.statusRawValue = string(record, "status", fallback: VoxiverseReportStatus.new.rawValue)
        report.submittedDate = record["submittedAt"] as? Date ?? record.creationDate ?? report.submittedDate
        report.reporter = reporterName(from: record, fallback: report.reporter)
        report.deviceModel = string(record, "deviceModel")
        report.iOSVersion = string(record, "iOSVersion")
        report.appVersion = string(record, "appVersion")
        report.buildNumber = string(record, "buildNumber")
        report.screenName = string(record, "screenName")
        report.internalNotes = string(record, "internalNotes")
        report.overallExperience = string(record, "overallExperience")
        report.testedWhat = string(record, "testedWhat", fallback: string(record, "descriptionText"))
        report.workedWell = string(record, "workedWell")
        report.couldBeBetter = string(record, "couldBeBetter")
        report.anythingUnexpected = string(record, "anythingUnexpected")
    }

    private static func apply(_ record: CKRecord, to request: VoxiverseFeatureRequest) {
        request.appID = canonicalAppID(from: record)
        request.title = string(record, "title")
        request.requestDescription = string(record, "descriptionText")
        request.category = string(record, "category")
        request.featureType = string(record, "featureType")
        request.featureImportance = string(record, "importance")
        request.intendedAudience = string(record, "intendedAudience")
        request.featureDescription = string(record, "featureDescription")
        request.imaginedWorkflow = string(record, "imaginedWorkflow")
        request.desiredLocation = string(record, "desiredLocation")
        request.relatedExistingFeature = string(record, "relatedExistingFeature")
        request.problemAddressed = string(record, "problemAddressed")
        request.desiredResult = string(record, "desiredResult")
        request.requiresSavedData = string(record, "requiresSavedData")
        request.needsNotifications = string(record, "needsNotifications")
        request.needsSharing = string(record, "needsSharing")
        request.needsAI = string(record, "needsAI")
        request.additionalDetails = string(record, "additionalDetails")
        request.deviceModel = string(record, "deviceModel")
        request.iOSVersion = string(record, "iOSVersion")
        request.appVersion = string(record, "appVersion")
        request.buildNumber = string(record, "buildNumber")
        request.bundleIdentifier = string(record, "bundleIdentifier")
        request.screenName = string(record, "screenName")
        request.locale = string(record, "locale")
        request.timeZone = string(record, "timeZone")
        request.statusRawValue = string(record, "status", fallback: VoxiverseFeatureRequestStatus.new.rawValue)
        request.requestCount = integer(record, "requestCount")
        request.updatedDate = record["updatedAt"] as? Date ?? record["submittedAt"] as? Date ?? request.updatedDate
        request.submitter = reporterName(from: record, fallback: request.submitter)
        request.internalNotes = string(record, "internalNotes")
    }

    private static func string(_ record: CKRecord, _ key: String, fallback: String = "") -> String {
        (record[key] as? String) ?? fallback
    }

    private static func integer(_ record: CKRecord, _ key: String) -> Int {
        if let value = record[key] as? Int { return value }
        if let value = record[key] as? Int64 { return Int(value) }
        if let value = record[key] as? NSNumber { return value.intValue }
        return 0
    }

    private static func reporterName(from record: CKRecord, fallback: String = "") -> String {
        let explicitReporter = string(record, "reporterName").trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicitReporter.isEmpty {
            return explicitReporter
        }

        let existingFallback = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
        if !existingFallback.isEmpty, existingFallback != "Unknown" {
            return existingFallback
        }

        if let creatorRecordName = record.creatorUserRecordID?.recordName.trimmingCharacters(in: .whitespacesAndNewlines),
           !creatorRecordName.isEmpty {
            return creatorRecordName
        }

        if canonicalAppID(from: record) == "loomey" {
            return "Loomey User"
        }

        return existingFallback.isEmpty ? "Unknown" : existingFallback
    }

    @MainActor
    private static func managedApp(for appID: String, in modelContext: ModelContext) throws -> VoxiverseManagedApp? {
        guard !appID.isEmpty else { return nil }
        let canonicalID = VoxiverseAppIdentity.canonicalID(appID)
        let descriptor = FetchDescriptor<VoxiverseManagedApp>(
            predicate: #Predicate { $0.id == canonicalID }
        )
        let exactMatches = try modelContext.fetch(descriptor)
        if let exactMatch = exactMatches.first {
            return exactMatch
        }

        let allApps = try modelContext.fetch(FetchDescriptor<VoxiverseManagedApp>())
        return allApps.matchingApp(id: canonicalID)
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
            return VoxiverseAppIdentity.canonicalID(appName)
        }
        let bundle = string(record, "appID").lowercased()
        if bundle.contains("asterium") || bundle.contains("sterium") { return "sterium" }
        return bundle.isEmpty ? "unknown" : VoxiverseAppIdentity.canonicalID(bundle)
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

    @MainActor
    private static func replaceAttachments(
        from record: CKRecord,
        for request: VoxiverseFeatureRequest,
        in modelContext: ModelContext
    ) {
        for attachment in request.attachments ?? [] {
            modelContext.delete(attachment)
        }

        let attachments = attachmentModels(from: record)
        request.attachments = attachments

        for attachment in attachments {
            attachment.featureRequest = request
            modelContext.insert(attachment)
        }
    }

    private static func attachmentModels(from record: CKRecord) -> [VoxiverseReportAttachment] {
        (1...3).compactMap { index in
            guard let asset = record["attachment\(index)"] as? CKAsset else { return nil }
            let resolvedFilename = asset.fileURL?.lastPathComponent ?? ""
            let displayName = attachmentDisplayName(
                resolvedFilename: resolvedFilename,
                fallbackIndex: index
            )
            let localFileName = asset.fileURL.flatMap { fileURL in
                do {
                    return try persistAttachmentFile(
                        from: fileURL,
                        recordName: record.recordID.recordName,
                        index: index,
                        filename: resolvedFilename
                    )
                } catch {
                    print("Voxiverse attachment copy failed: \(error)")
                    return nil
                }
            }

            return VoxiverseReportAttachment(
                id: "\(record.recordID.recordName)-attachment-\(index)",
                name: displayName,
                detail: attachmentDetail(for: asset.fileURL),
                assetName: "imagesign",
                localFileName: localFileName
            )
        }
    }

    private static func attachmentDisplayName(resolvedFilename: String, fallbackIndex: Int) -> String {
        if let stableIdentifier = VoxiverseReportAttachment.stableIdentifier(fromResolvedFilename: resolvedFilename) {
            return stableIdentifier
        }

        let trimmedFilename = resolvedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedFilename.isEmpty {
            return URL(fileURLWithPath: trimmedFilename).lastPathComponent
        }

        return "Attachment \(fallbackIndex)"
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
        guard let fileURL else { return "Image" }
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let size = attributes[.size] as? NSNumber
        else {
            return "Image"
        }

        let sizeText = ByteCountFormatter.string(fromByteCount: size.int64Value, countStyle: .file)
        return "Image · \(sizeText)"
    }
}
