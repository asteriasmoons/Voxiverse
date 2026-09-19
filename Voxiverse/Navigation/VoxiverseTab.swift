enum VoxiverseTab: String, CaseIterable, Identifiable {
    case home
    case apps
    case centerAction
    case reports
    case requests

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .apps: "Apps"
        case .centerAction: "Action"
        case .reports: "Reports"
        case .requests: "Requests"
        }
    }

    var assetName: String {
        switch self {
        case .home: "houseoutline"
        case .apps: "sparkledevice"
        case .centerAction: "addwavy"
        case .reports: "starladder"
        case .requests: "bulbxoxo"
        }
    }
}
