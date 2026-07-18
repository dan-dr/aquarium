import AppKit
import CoreGraphics
import Foundation

struct HotkeyOption: Codable, Hashable, Identifiable {
    enum Kind: String, Codable {
        case modifierOnly
        case keyboard
    }

    let keyCode: Int64
    let modifiersRawValue: UInt64
    let keyLabel: String
    let kind: Kind

    var id: String {
        "\(kind.rawValue):\(keyCode):\(modifiersRawValue)"
    }

    var displayName: String {
        guard kind == .keyboard else { return keyLabel }
        return Self.modifierGlyphs(for: modifiers) + keyLabel
    }

    var modifiers: CGEventFlags {
        CGEventFlags(rawValue: modifiersRawValue)
    }

    var isModifierOnly: Bool {
        kind == .modifierOnly
    }

    private init(
        keyCode: Int64,
        modifiersRawValue: UInt64,
        keyLabel: String,
        kind: Kind
    ) {
        self.keyCode = keyCode
        self.modifiersRawValue = modifiersRawValue
        self.keyLabel = keyLabel
        self.kind = kind
    }

    func isPressed(in flags: CGEventFlags) -> Bool {
        flags.contains(modifiers)
    }

    func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        guard kind == .keyboard, self.keyCode == keyCode else { return false }
        return flags.intersection(Self.supportedModifierMask) == modifiers
    }

    static let rightCommand = modifier(
        keyCode: 54,
        flag: .maskCommand,
        label: "Right Command"
    )
    static let rightOption = modifier(
        keyCode: 61,
        flag: .maskAlternate,
        label: "Right Option"
    )
    static let rightControl = modifier(
        keyCode: 62,
        flag: .maskControl,
        label: "Right Control"
    )
    static let suggestedAquaRelay = keyboard(
        keyCode: 64,
        modifiers: [
            .maskCommand,
            .maskAlternate,
            .maskControl,
            .maskShift,
        ],
        keyLabel: "F17"
    )
    static let suggestedTriggers = [rightCommand, rightOption, rightControl]

    static func keyboard(
        keyCode: Int64,
        modifiers: CGEventFlags,
        keyLabel: String
    ) -> HotkeyOption {
        HotkeyOption(
            keyCode: keyCode,
            modifiersRawValue: modifiers
                .intersection(supportedModifierMask)
                .rawValue,
            keyLabel: keyLabel,
            kind: .keyboard
        )
    }

    static func modifierOnly(keyCode: Int64) -> HotkeyOption? {
        modifierHotkeys[keyCode]
    }

    static func modifierChord(
        keyCode: Int64,
        modifiers: CGEventFlags
    ) -> HotkeyOption? {
        guard let physicalKey = modifierHotkeys[keyCode] else { return nil }
        let recordedModifiers = modifiers.intersection(supportedModifierMask)
        guard
            !recordedModifiers.isEmpty,
            recordedModifiers.contains(physicalKey.modifiers)
        else {
            return nil
        }
        if recordedModifiers == physicalKey.modifiers {
            return physicalKey
        }
        return HotkeyOption(
            keyCode: keyCode,
            modifiersRawValue: recordedModifiers.rawValue,
            keyLabel: modifierGlyphs(for: recordedModifiers),
            kind: .modifierOnly
        )
    }

    static func eventFlags(from flags: NSEvent.ModifierFlags) -> CGEventFlags {
        var result: CGEventFlags = []
        if flags.contains(.command) { result.insert(.maskCommand) }
        if flags.contains(.option) { result.insert(.maskAlternate) }
        if flags.contains(.control) { result.insert(.maskControl) }
        if flags.contains(.shift) { result.insert(.maskShift) }
        if flags.contains(.function) { result.insert(.maskSecondaryFn) }
        return result
    }

    static func keyLabel(for event: NSEvent) -> String {
        if let label = specialKeyLabels[event.keyCode] { return label }
        let characters = event.charactersIgnoringModifiers ?? ""
        let trimmed = characters.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Key \(event.keyCode)" : trimmed.uppercased()
    }

    init(from decoder: Decoder) throws {
        if let legacyValue = try? decoder.singleValueContainer().decode(
            String.self
        ) {
            switch legacyValue {
            case "MetaRight": self = .rightCommand
            case "AltRight": self = .rightOption
            case "ControlRight": self = .rightControl
            default:
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown legacy hotkey \(legacyValue)"
                    )
                )
            }
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(Int64.self, forKey: .keyCode)
        modifiersRawValue = try container.decode(
            UInt64.self,
            forKey: .modifiersRawValue
        )
        keyLabel = try container.decode(String.self, forKey: .keyLabel)
        kind = try container.decode(Kind.self, forKey: .kind)
    }

    private enum CodingKeys: String, CodingKey {
        case keyCode
        case modifiersRawValue
        case keyLabel
        case kind
    }

    private static let supportedModifierMask: CGEventFlags = [
        .maskCommand,
        .maskAlternate,
        .maskControl,
        .maskShift,
        .maskSecondaryFn,
    ]

    private static let modifierHotkeys: [Int64: HotkeyOption] = [
        54: rightCommand,
        55: modifier(keyCode: 55, flag: .maskCommand, label: "Left Command"),
        61: rightOption,
        58: modifier(keyCode: 58, flag: .maskAlternate, label: "Left Option"),
        62: rightControl,
        59: modifier(keyCode: 59, flag: .maskControl, label: "Left Control"),
        60: modifier(keyCode: 60, flag: .maskShift, label: "Right Shift"),
        56: modifier(keyCode: 56, flag: .maskShift, label: "Left Shift"),
        63: modifier(keyCode: 63, flag: .maskSecondaryFn, label: "Fn"),
    ]

    private static let specialKeyLabels: [UInt16: String] = [
        36: "Return",
        48: "Tab",
        49: "Space",
        51: "Delete",
        53: "Escape",
        115: "Home",
        116: "Page Up",
        117: "Forward Delete",
        119: "End",
        121: "Page Down",
        123: "←",
        124: "→",
        125: "↓",
        126: "↑",
        122: "F1",
        120: "F2",
        99: "F3",
        118: "F4",
        96: "F5",
        97: "F6",
        98: "F7",
        100: "F8",
        101: "F9",
        109: "F10",
        103: "F11",
        111: "F12",
        105: "F13",
        107: "F14",
        113: "F15",
        106: "F16",
        64: "F17",
        79: "F18",
        80: "F19",
        90: "F20",
    ]

    private static func modifier(
        keyCode: Int64,
        flag: CGEventFlags,
        label: String
    ) -> HotkeyOption {
        HotkeyOption(
            keyCode: keyCode,
            modifiersRawValue: flag.rawValue,
            keyLabel: label,
            kind: .modifierOnly
        )
    }

    private static func modifierGlyphs(for flags: CGEventFlags) -> String {
        var result = ""
        if flags.contains(.maskControl) { result += "⌃" }
        if flags.contains(.maskAlternate) { result += "⌥" }
        if flags.contains(.maskShift) { result += "⇧" }
        if flags.contains(.maskCommand) { result += "⌘" }
        if flags.contains(.maskSecondaryFn) { result += "Fn " }
        return result
    }
}
