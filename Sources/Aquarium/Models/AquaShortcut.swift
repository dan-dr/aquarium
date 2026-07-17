import CoreGraphics
import Foundation

struct AquaShortcut: Equatable {
    let keyCode: CGKeyCode
    let flags: CGEventFlags

    init?(_ value: String) {
        let components = value
            .split(separator: "+")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let keyName = components.last,
              let keyCode = Self.functionKeyCodes[keyName.uppercased()]
        else {
            return nil
        }

        var flags: CGEventFlags = []
        for component in components.dropLast() {
            switch component.lowercased() {
            case "meta", "metaright", "command", "commandright":
                flags.insert(.maskCommand)
            case "alt", "altright", "option", "optionright":
                flags.insert(.maskAlternate)
            case "control", "controlright", "ctrl", "ctrlright":
                flags.insert(.maskControl)
            case "shift", "shiftright":
                flags.insert(.maskShift)
            default:
                return nil
            }
        }

        guard !flags.isEmpty else { return nil }
        self.keyCode = keyCode
        self.flags = flags
    }

    func includesTrigger(_ hotkey: HotkeyOption) -> Bool {
        flags.contains(hotkey.modifierFlag)
    }

    private static let functionKeyCodes: [String: CGKeyCode] = [
        "F13": 105,
        "F14": 107,
        "F15": 113,
        "F16": 106,
        "F17": 64,
        "F18": 79,
        "F19": 80,
        "F20": 90,
    ]
}
