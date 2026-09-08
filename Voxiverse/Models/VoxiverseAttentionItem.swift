import Foundation

struct VoxiverseAttentionItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let assetName: String
    let accent: VoxiverseMetricAccent
    let reportID: String?
}
