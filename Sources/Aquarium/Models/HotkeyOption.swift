import CoreGraphics

enum HotkeyOption: String, CaseIterable, Codable, Identifiable {
    case rightCommand = "MetaRight"
    case rightOption = "AltRight"
    case rightControl = "ControlRight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rightCommand: "Right Command"
        case .rightOption: "Right Option"
        case .rightControl: "Right Control"
        }
    }

    var glyph: String {
        switch self {
        case .rightCommand: "⌘"
        case .rightOption: "⌥"
        case .rightControl: "⌃"
        }
    }

    var keyCode: Int64 {
        switch self {
        case .rightCommand: 54
        case .rightOption: 61
        case .rightControl: 62
        }
    }

    func isPressed(in flags: CGEventFlags) -> Bool {
        switch self {
        case .rightCommand: flags.contains(.maskCommand)
        case .rightOption: flags.contains(.maskAlternate)
        case .rightControl: flags.contains(.maskControl)
        }
    }
}
