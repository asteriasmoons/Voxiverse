import SwiftUI

enum VoxiverseColor {
    static let background = Color(red: 16.0 / 255.0, green: 16.0 / 255.0, blue: 20.0 / 255.0)
    static let surface = Color(red: 27.0 / 255.0, green: 26.0 / 255.0, blue: 32.0 / 255.0)
    static let raisedSurface = Color(red: 40.0 / 255.0, green: 38.0 / 255.0, blue: 46.0 / 255.0)
    static let primaryAction = Color(red: 136.0 / 255.0, green: 117.0 / 255.0, blue: 181.0 / 255.0)
    static let secondaryAccent = Color(red: 161.0 / 255.0, green: 35.0 / 255.0, blue: 111.0 / 255.0)
    static let indicator = Color(red: 113.0 / 255.0, green: 135.0 / 255.0, blue: 184.0 / 255.0)
    static let primaryText = Color(red: 247.0 / 255.0, green: 246.0 / 255.0, blue: 248.0 / 255.0)
    static let secondaryText = Color(red: 171.0 / 255.0, green: 168.0 / 255.0, blue: 176.0 / 255.0)
    static let divider = primaryText.opacity(0.08)
}

enum VoxiverseMetricAccent: Hashable {
    case primary
    case secondary
    case indicator

    var color: Color {
        switch self {
        case .primary: VoxiverseColor.primaryAction
        case .secondary: VoxiverseColor.secondaryAccent
        case .indicator: VoxiverseColor.indicator
        }
    }
}

enum VoxiverseSpacing {
    static let pageHorizontal: CGFloat = 20
    static let section: CGFloat = 26
    static let card: CGFloat = 14
    static let compact: CGFloat = 10
}
