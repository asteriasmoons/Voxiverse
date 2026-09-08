import Foundation
import SwiftData

enum VoxiverseFeatureRequestStatus: String, CaseIterable, Codable, Hashable {
    case new = "New"
    case considering = "Considering"
    case planned = "Planned"
    case inProgress = "In Progress"
    case shipped = "Shipped"
    case declined = "Declined"
}

@Model
final class VoxiverseFeatureRequest: Identifiable {
    var id: String = UUID().uuidString
    var appID: String = ""
    var title: String = ""
    var requestDescription: String = ""
    var statusRawValue: String = VoxiverseFeatureRequestStatus.new.rawValue
    var requestCount: Int = 0
    var createdDate: Date = Date.now
    var updatedDate: Date = Date.now
    var submitter: String = ""
    var internalNotes: String = ""
    var app: VoxiverseManagedApp?

    var description: String { requestDescription }

    var status: VoxiverseFeatureRequestStatus {
        get { VoxiverseFeatureRequestStatus(rawValue: statusRawValue) ?? .new }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        appID: String,
        title: String,
        description: String,
        status: VoxiverseFeatureRequestStatus,
        requestCount: Int,
        createdDate: Date,
        updatedDate: Date,
        submitter: String,
        internalNotes: String
    ) {
        self.id = id
        self.appID = appID
        self.title = title
        self.requestDescription = description
        self.statusRawValue = status.rawValue
        self.requestCount = requestCount
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.submitter = submitter
        self.internalNotes = internalNotes
    }
}
