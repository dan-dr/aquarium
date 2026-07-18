import CoreGraphics
import Foundation

struct AquaShortcut: Equatable {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
    let isModifierOnly: Bool
    let hotkey: HotkeyOption

    init?(_ value: String) {
        let components = value
            .split(separator: "+")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard let keyName = components.last else { return nil }

        if components.allSatisfy({
            Self.modifierFlags[$0.lowercased()] != nil
        }),
           let trigger = Self.modifierOnlyKeys[keyName.lowercased()]
        {
            let recordedFlags = components.reduce(into: CGEventFlags()) {
                result, component in
                if let flag = Self.modifierFlags[component.lowercased()] {
                    result.insert(flag)
                }
            }
            guard let recordedHotkey = HotkeyOption.modifierChord(
                keyCode: Int64(trigger.keyCode),
                modifiers: recordedFlags
            ) else { return nil }
            keyCode = trigger.keyCode
            flags = recordedFlags
            isModifierOnly = true
            hotkey = recordedHotkey
            return
        }

        guard let resolvedKeyCode = Self.keyCodes[keyName.uppercased()] else {
            return nil
        }

        var resolvedFlags: CGEventFlags = []
        for component in components.dropLast() {
            guard let flag = Self.modifierFlags[component.lowercased()] else {
                return nil
            }
            resolvedFlags.insert(flag)
        }

        keyCode = resolvedKeyCode
        flags = resolvedFlags
        isModifierOnly = false
        hotkey = .keyboard(
            keyCode: Int64(resolvedKeyCode),
            modifiers: resolvedFlags,
            keyLabel: Self.displayLabel(for: keyName)
        )
    }

    func conflicts(with trigger: HotkeyOption) -> Bool {
        guard isModifierOnly == trigger.isModifierOnly else { return false }
        guard keyCode == trigger.keyCode else { return false }
        return isModifierOnly || flags == trigger.modifiers
    }

    private static func displayLabel(for keyName: String) -> String {
        let uppercased = keyName.uppercased()
        if uppercased.hasPrefix("KEY"), uppercased.count == 4 {
            return String(uppercased.suffix(1))
        }
        if uppercased.hasPrefix("DIGIT"), uppercased.count == 6 {
            return String(uppercased.suffix(1))
        }
        return switch uppercased {
        case "ARROWLEFT": "←"
        case "ARROWRIGHT": "→"
        case "ARROWDOWN": "↓"
        case "ARROWUP": "↑"
        case "BACKSPACE": "Delete"
        case "FORWARDDELETE": "Forward Delete"
        case "PAGEUP": "Page Up"
        case "PAGEDOWN": "Page Down"
        default: keyName
        }
    }

    private static let modifierFlags: [String: CGEventFlags] = [
        "meta": .maskCommand,
        "metaleft": .maskCommand,
        "metaright": .maskCommand,
        "command": .maskCommand,
        "commandleft": .maskCommand,
        "commandright": .maskCommand,
        "alt": .maskAlternate,
        "altleft": .maskAlternate,
        "altright": .maskAlternate,
        "option": .maskAlternate,
        "optionleft": .maskAlternate,
        "optionright": .maskAlternate,
        "control": .maskControl,
        "controlleft": .maskControl,
        "controlright": .maskControl,
        "ctrl": .maskControl,
        "ctrlleft": .maskControl,
        "ctrlright": .maskControl,
        "shift": .maskShift,
        "shiftleft": .maskShift,
        "shiftright": .maskShift,
    ]

    private static let modifierOnlyKeys: [
        String: (keyCode: CGKeyCode, flag: CGEventFlags)
    ] = [
        "meta": (55, .maskCommand),
        "metaleft": (55, .maskCommand),
        "metaright": (54, .maskCommand),
        "command": (55, .maskCommand),
        "commandleft": (55, .maskCommand),
        "commandright": (54, .maskCommand),
        "alt": (58, .maskAlternate),
        "altleft": (58, .maskAlternate),
        "altright": (61, .maskAlternate),
        "option": (58, .maskAlternate),
        "optionleft": (58, .maskAlternate),
        "optionright": (61, .maskAlternate),
        "control": (59, .maskControl),
        "controlleft": (59, .maskControl),
        "controlright": (62, .maskControl),
        "ctrl": (59, .maskControl),
        "ctrlleft": (59, .maskControl),
        "ctrlright": (62, .maskControl),
        "shift": (56, .maskShift),
        "shiftleft": (56, .maskShift),
        "shiftright": (60, .maskShift),
    ]

    private static let keyCodes: [String: CGKeyCode] = [
        "KEYA": 0, "KEYS": 1, "KEYD": 2, "KEYF": 3,
        "KEYH": 4, "KEYG": 5, "KEYZ": 6, "KEYX": 7,
        "KEYC": 8, "KEYV": 9, "INTLBACKSLASH": 10,
        "KEYB": 11, "KEYQ": 12,
        "KEYW": 13, "KEYE": 14, "KEYR": 15, "KEYY": 16,
        "KEYT": 17, "DIGIT1": 18, "DIGIT2": 19, "DIGIT3": 20,
        "DIGIT4": 21, "DIGIT6": 22, "DIGIT5": 23, "EQUAL": 24,
        "DIGIT9": 25, "DIGIT7": 26, "MINUS": 27, "DIGIT8": 28,
        "DIGIT0": 29, "BRACKETRIGHT": 30, "KEYO": 31, "KEYU": 32,
        "BRACKETLEFT": 33, "KEYI": 34, "KEYP": 35, "RETURN": 36,
        "ENTER": 36, "KEYL": 37, "KEYJ": 38, "QUOTE": 39,
        "KEYK": 40, "SEMICOLON": 41, "BACKSLASH": 42, "COMMA": 43,
        "SLASH": 44, "KEYN": 45, "KEYM": 46, "PERIOD": 47,
        "TAB": 48, "SPACE": 49, "BACKQUOTE": 50, "BACKSPACE": 51,
        "DELETE": 51, "ESCAPE": 53, "CAPSLOCK": 57,
        "NUMPADDECIMAL": 65, "NUMPADMULTIPLY": 67,
        "NUMPADADD": 69, "NUMLOCK": 71, "NUMPADCLEAR": 71,
        "NUMPADDIVIDE": 75, "NUMPADENTER": 76,
        "NUMPADSUBTRACT": 78, "NUMPADEQUAL": 81,
        "NUMPAD0": 82, "NUMPAD1": 83, "NUMPAD2": 84,
        "NUMPAD3": 85, "NUMPAD4": 86, "NUMPAD5": 87,
        "NUMPAD6": 88, "NUMPAD7": 89, "NUMPAD8": 91,
        "NUMPAD9": 92, "HELP": 114, "HOME": 115, "PAGEUP": 116,
        "FORWARDDELETE": 117, "END": 119, "PAGEDOWN": 121,
        "ARROWLEFT": 123, "ARROWRIGHT": 124,
        "ARROWDOWN": 125, "ARROWUP": 126,
        "F1": 122, "F2": 120, "F3": 99, "F4": 118,
        "F5": 96, "F6": 97, "F7": 98, "F8": 100,
        "F9": 101, "F10": 109, "F11": 103, "F12": 111,
        "F13": 105, "F14": 107, "F15": 113, "F16": 106,
        "F17": 64, "F18": 79, "F19": 80, "F20": 90,
    ]
}
