import Foundation

struct VoxiverseAttentionItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let assetName: String
    let accent: VoxiverseMetricAccent
    let reportID: String?
    let requestID: String?
    let appID: String
    let date: Date
    let sortRank: Int
}

enum VoxiverseDashboardData {
    static func openReportCount(_ reports: [VoxiverseReport]) -> Int {
        reports.filter { $0.countsAsOpen }.count
    }

    static func openReportCount(for appID: String, reports: [VoxiverseReport]) -> Int {
        let canonicalID = VoxiverseAppIdentity.canonicalID(appID)
        return reports.filter {
            VoxiverseAppIdentity.canonicalID($0.appID) == canonicalID && $0.countsAsOpen
        }.count
    }

    static func needsAttention(
        reports: [VoxiverseReport],
        requests: [VoxiverseFeatureRequest],
        apps: [VoxiverseManagedApp]
    ) -> [VoxiverseAttentionItem] {
        let reportItems = reports.compactMap { report -> VoxiverseAttentionItem? in
            guard report.requiresAttention else { return nil }
            let appName = apps.matchingApp(id: report.appID)?.name ?? "Unknown App"
            let rank = attentionRank(for: report)
            let accent: VoxiverseMetricAccent = report.priority == .critical || report.priority == .high
                ? .secondary
                : report.status == .actionNeeded ? .primary : .indicator
            let assetName = report.reportType == .betaFeedback ? "chatsparkle" : "bug"
            let typeText = report.reportType == .betaFeedback ? "Beta Feedback" : "Bug Report"
            return VoxiverseAttentionItem(
                id: "report-\(report.id)",
                title: report.title,
                detail: "\(appName) · \(typeText) · \(report.status.rawValue)",
                assetName: assetName,
                accent: accent,
                reportID: report.id,
                requestID: nil,
                appID: report.appID,
                date: report.submittedDate,
                sortRank: rank
            )
        }

        let requestItems = requests.compactMap { request -> VoxiverseAttentionItem? in
            guard request.status == .new else { return nil }
            let appName = apps.matchingApp(id: request.appID)?.name ?? "Unknown App"
            return VoxiverseAttentionItem(
                id: "request-\(request.id)",
                title: request.title,
                detail: "\(appName) · Feature Request · \(request.status.rawValue)",
                assetName: "bulbxoxo",
                accent: .primary,
                reportID: nil,
                requestID: request.id,
                appID: request.appID,
                date: request.updatedDate,
                sortRank: 3
            )
        }

        return (reportItems + requestItems).sorted {
            if $0.sortRank != $1.sortRank { return $0.sortRank < $1.sortRank }
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    private static func attentionRank(for report: VoxiverseReport) -> Int {
        if report.reportType == .bugReport && report.priority == .critical { return 0 }
        if report.reportType == .bugReport && report.priority == .high { return 1 }
        if report.reportType == .betaFeedback && report.status == .actionNeeded { return 2 }
        if report.status == .new { return 3 }
        if report.reportType == .bugReport && report.status == .reviewing { return 4 }
        return 5
    }
}
