import Foundation
import SwiftData

enum VoxiverseSampleData {
    private static let now = Date()
    private static let seedKey = "VoxiverseSampleDataSeeded"

    static let apps: [VoxiverseManagedApp] = [
        VoxiverseManagedApp(id: "sterium", name: "Sterium", description: "A calm space for visual thinking.", version: "1.8.0", buildNumber: "184", status: .active, bundleIdentifier: "im.lystaria.Sterium", platform: "iPhone & iPad", iconAssetName: "sterium", openReportCount: 4, featureRequestCount: 7, betaBuildCount: 0, sortOrder: 0, createdDate: now.addingTimeInterval(-2_100_000), updatedDate: now.addingTimeInterval(-18_000)),
        VoxiverseManagedApp(id: "lurelia", name: "Lurelia", description: "Routines and gentle momentum.", version: "2.4.1", buildNumber: "241", status: .beta, bundleIdentifier: "im.lystaria.Lurelia", platform: "iPhone", iconAssetName: "lurelia", openReportCount: 3, featureRequestCount: 5, betaBuildCount: 2, sortOrder: 1, createdDate: now.addingTimeInterval(-1_700_000), updatedDate: now.addingTimeInterval(-44_000)),
        VoxiverseManagedApp(id: "loomey", name: "Loomey", description: "A softer way to keep a reading life.", version: "1.3.2", buildNumber: "132", status: .beta, bundleIdentifier: "im.lystaria.Loomey", platform: "iPhone & iPad", iconAssetName: "loomey", openReportCount: 2, featureRequestCount: 9, betaBuildCount: 1, sortOrder: 2, createdDate: now.addingTimeInterval(-1_300_000), updatedDate: now.addingTimeInterval(-76_000)),
        VoxiverseManagedApp(id: "dotti", name: "Dotti", description: "A tiny home for everyday details.", version: "1.1.0", buildNumber: "110", status: .active, bundleIdentifier: "im.lystaria.Dotti", platform: "iPhone", iconAssetName: "dotcake", openReportCount: 1, featureRequestCount: 4, betaBuildCount: 0, sortOrder: 3, createdDate: now.addingTimeInterval(-920_000), updatedDate: now.addingTimeInterval(-110_000)),
        VoxiverseManagedApp(id: "lunixia", name: "Lunixia", description: "Health routines that feel human.", version: "3.0.0", buildNumber: "300", status: .development, bundleIdentifier: "im.lystaria.Lunixia", platform: "iPhone & Watch", iconAssetName: "lunixia", openReportCount: 0, featureRequestCount: 3, betaBuildCount: 0, sortOrder: 4, createdDate: now.addingTimeInterval(-760_000), updatedDate: now.addingTimeInterval(-152_000)),
        VoxiverseManagedApp(id: "voxterm", name: "VoxTerm", description: "Focused tools for remote work.", version: "0.9.4", buildNumber: "94", status: .beta, bundleIdentifier: "im.lystaria.VoxTerm", platform: "iPhone & iPad", iconAssetName: "voxterm", openReportCount: 1, featureRequestCount: 6, betaBuildCount: 3, sortOrder: 5, createdDate: now.addingTimeInterval(-620_000), updatedDate: now.addingTimeInterval(-210_000)),
        VoxiverseManagedApp(id: "asterium", name: "Asterium", description: "A place for ideas with room to grow.", version: "0.7.0", buildNumber: "70", status: .development, bundleIdentifier: "im.lystaria.Asterium", platform: "iPhone", iconAssetName: "starcircle", openReportCount: 0, featureRequestCount: 2, betaBuildCount: 0, sortOrder: 6, createdDate: now.addingTimeInterval(-420_000), updatedDate: now.addingTimeInterval(-260_000)),
        VoxiverseManagedApp(id: "markli", name: "Markli", description: "Small marks for meaningful moments.", version: "0.4.0", buildNumber: "40", status: .archived, bundleIdentifier: "im.lystaria.Markli", platform: "iPhone", iconAssetName: "markcircle", openReportCount: 0, featureRequestCount: 1, betaBuildCount: 0, sortOrder: 7, createdDate: now.addingTimeInterval(-2_900_000), updatedDate: now.addingTimeInterval(-650_000))
    ]

    static let reports: [VoxiverseReport] = [
        VoxiverseReport(id: "report-sterium-image-move", reportID: "VX-1042", appID: "sterium", title: "Vision Board image won't move", description: "The image is not moving to the selected folder.", expectedBehavior: "Selecting a folder should move the image to that folder.", stepsToReproduce: ["Open the Ideas board.", "Open an image.", "Select Move.", "Choose Color Palettes.", "Confirm the move."], reportType: .bugReport, priority: .high, status: .new, submittedDate: now.addingTimeInterval(-3_600), reporter: "Maya R.", deviceModel: "iPhone 16 Pro", iOSVersion: "26.0", appVersion: "1.8.0", buildNumber: "184", screenName: "Vision Board", internalNotes: "Reproduced twice on the current production build.", attachments: [VoxiverseReportAttachment(id: "attachment-1042", name: "vision-board-screen", detail: "PNG · 1.8 MB", assetName: "imagesign")]),
        VoxiverseReport(id: "report-lurelia-widget", reportID: "VX-1039", appID: "lurelia", title: "Routine widget not refreshing", description: "The widget keeps showing yesterday's routine after the morning check-in.", expectedBehavior: "The widget should refresh after a routine is completed.", stepsToReproduce: ["Complete a routine task.", "Return to the Home Screen.", "Wait for the widget to refresh."], reportType: .bugReport, priority: .medium, status: .inProgress, submittedDate: now.addingTimeInterval(-86_400), reporter: "Jordan K.", deviceModel: "iPhone 15", iOSVersion: "26.0", appVersion: "2.4.1", buildNumber: "241", screenName: "Home Screen Widget", internalNotes: "Compare shared app-group snapshot timestamps with the widget timeline.", attachments: []),
        VoxiverseReport(id: "report-loomey-notes", reportID: "VX-1037", appID: "loomey", title: "Reading session notes disappear after save", description: "Notes entered during a reading session are missing when the session is reopened.", expectedBehavior: "Saved notes should remain attached to the reading session.", stepsToReproduce: ["Open an active reading session.", "Add a note.", "Save and close the session.", "Reopen the session."], reportType: .betaFeedback, priority: .medium, status: .new, submittedDate: now.addingTimeInterval(-172_800), reporter: "Ari S.", deviceModel: "iPhone 14 Pro", iOSVersion: "26.0", appVersion: "1.3.2", buildNumber: "132", screenName: "Reading Session", internalNotes: "Needs a persistence pass before the next beta build.", attachments: []),
        VoxiverseReport(id: "report-voxterm-ssh", reportID: "VX-1028", appID: "voxterm", title: "SSH session disconnects unexpectedly", description: "An active SSH session disconnects after the device sleeps briefly.", expectedBehavior: "The session should reconnect or clearly preserve its disconnected state.", stepsToReproduce: ["Connect to an SSH host.", "Let the device sleep for one minute.", "Wake the device and return to the terminal."], reportType: .bugReport, priority: .high, status: .resolved, submittedDate: now.addingTimeInterval(-345_600), reporter: "Chris T.", deviceModel: "iPad Pro 13-inch", iOSVersion: "26.0", appVersion: "0.9.4", buildNumber: "94", screenName: "Terminal Session", internalNotes: "Resolved in build 94 by restoring the canonical session route.", attachments: []),
        VoxiverseReport(id: "report-dotti-layout", reportID: "VX-1019", appID: "dotti", title: "Love the new layout", description: "The new home layout makes the daily details feel much easier to scan.", expectedBehavior: "Keep the visual hierarchy and quick access in future revisions.", stepsToReproduce: ["Open Dotti.", "Review the Home screen."], reportType: .generalFeedback, priority: .low, status: .resolved, submittedDate: now.addingTimeInterval(-518_400), reporter: "Nina W.", deviceModel: "iPhone 16", iOSVersion: "26.0", appVersion: "1.1.0", buildNumber: "110", screenName: "Home", internalNotes: "Share with the design notes for the next milestone.", attachments: [])
    ]

    static let featureRequests: [VoxiverseFeatureRequest] = [
        VoxiverseFeatureRequest(id: "request-sterium-tags", appID: "sterium", title: "Add board tags", description: "Group visual boards with lightweight tags.", status: .considering, requestCount: 12, createdDate: now.addingTimeInterval(-125_000), updatedDate: now.addingTimeInterval(-50_000), submitter: "Maya R.", internalNotes: "Review after the folder-move fix."),
        VoxiverseFeatureRequest(id: "request-lurelia-shared", appID: "lurelia", title: "Shared routines", description: "Allow a routine to be shared with a partner.", status: .planned, requestCount: 8, createdDate: now.addingTimeInterval(-210_000), updatedDate: now.addingTimeInterval(-80_000), submitter: "Jordan K.", internalNotes: "Requires a sync design pass."),
        VoxiverseFeatureRequest(id: "request-loomey-highlights", appID: "loomey", title: "Reading highlights", description: "Save a small set of highlights beside a session.", status: .new, requestCount: 15, createdDate: now.addingTimeInterval(-290_000), updatedDate: now.addingTimeInterval(-120_000), submitter: "Ari S.", internalNotes: "Strong candidate for a later reading milestone.")
    ]

    static let attentionItems: [VoxiverseAttentionItem] = [
        VoxiverseAttentionItem(id: "attention-1042", title: "Vision Board image won't move", detail: "Sterium · High priority bug", assetName: "bug", accent: .secondary, reportID: "report-sterium-image-move"),
        VoxiverseAttentionItem(id: "attention-1039", title: "Routine widget needs a refresh", detail: "Lurelia · In progress", assetName: "clockwavy", accent: .indicator, reportID: "report-lurelia-widget"),
        VoxiverseAttentionItem(id: "attention-beta", title: "New beta feedback to review", detail: "Loomey · 2 days ago", assetName: "chatlinesfill", accent: .primary, reportID: "report-loomey-notes")
    ]

    static let activities: [VoxiverseActivity] = [
        VoxiverseActivity(id: "activity-1", title: "Report submitted", detail: "Sterium · VX-1042", date: now.addingTimeInterval(-3_600), assetName: "bug"),
        VoxiverseActivity(id: "activity-2", title: "Report status changed", detail: "VoxTerm · Resolved", date: now.addingTimeInterval(-345_600), assetName: "checkwavy"),
        VoxiverseActivity(id: "activity-3", title: "Feature request updated", detail: "Lurelia · Shared routines", date: now.addingTimeInterval(-86_400), assetName: "bulbxoxo"),
        VoxiverseActivity(id: "activity-4", title: "App build updated", detail: "Dotti · Build 110", date: now.addingTimeInterval(-110_000), assetName: "devwavy")
    ]

    @MainActor
    static func seedIfNeeded(in modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seedKey) else { return }

        let descriptor = FetchDescriptor<VoxiverseManagedApp>()
        guard let appCount = try? modelContext.fetchCount(descriptor), appCount == 0 else { return }

        let appByID = Dictionary(uniqueKeysWithValues: apps.map { ($0.id, $0) })
        for app in apps {
            modelContext.insert(app)
        }

        for report in reports {
            let attachments = report.attachments ?? []
            report.attachments = nil
            report.app = appByID[report.appID]
            modelContext.insert(report)
            for attachment in attachments {
                attachment.report = report
                modelContext.insert(attachment)
            }
        }

        for request in featureRequests {
            request.app = appByID[request.appID]
            modelContext.insert(request)
        }

        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: seedKey)
        } catch {
            // Leave the guard unset so a later launch can retry after a transient store error.
        }
    }
}
