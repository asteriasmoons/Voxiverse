//
//  VoxiverseDeepLinkRouter.swift
//  Voxiverse
//

import Combine
import Foundation

@MainActor
final class VoxiverseDeepLinkRouter: ObservableObject {
    @Published private(set) var pendingReportConversationID: String?

    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "voxiverse" else { return }
        let host = url.host?.lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        guard host == "report-conversation" || path == "report-conversation" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let reportID = components?.queryItems?.first(where: { $0.name == "reportID" || $0.name == "reportId" })?.value
        if let reportID, !reportID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pendingReportConversationID = reportID
        }
    }

    func consumePendingReportConversationID() -> String? {
        let value = pendingReportConversationID
        pendingReportConversationID = nil
        return value
    }
}
