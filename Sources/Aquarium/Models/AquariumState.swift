enum AquariumState: Equatable {
    case starting
    case ready
    case permissionRequired
    case unavailable(String)

    var label: String {
        switch self {
        case .starting: "Connecting to Aqua Voice…"
        case .ready: "Ready"
        case .permissionRequired: "Input Monitoring required"
        case let .unavailable(message): message
        }
    }

    var symbolName: String {
        switch self {
        case .starting: "fish"
        case .ready: "fish.fill"
        case .permissionRequired: "exclamationmark.triangle.fill"
        case .unavailable: "xmark.circle.fill"
        }
    }
}
