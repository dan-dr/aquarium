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

    var suggestedAquaShortcut: String {
        switch self {
        case .rightCommand: "MetaRight+F17"
        case .rightOption: "AltRight+F18"
        case .rightControl: "ControlRight+F19"
        }
    }

    var modifierFlag: CGEventFlags {
        switch self {
        case .rightCommand: .maskCommand
        case .rightOption: .maskAlternate
        case .rightControl: .maskControl
        }
    }

    func isPressed(in flags: CGEventFlags) -> Bool {
        flags.contains(modifierFlag)
    }
}
