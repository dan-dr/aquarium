import CoreGraphics
import XCTest
@testable import Aquarium

final class HotkeyOptionTests: XCTestCase {
    func testRightModifierKeyCodesMatchMacOS() {
        XCTAssertEqual(HotkeyOption.rightCommand.keyCode, 54)
        XCTAssertEqual(HotkeyOption.rightOption.keyCode, 61)
        XCTAssertEqual(HotkeyOption.rightControl.keyCode, 62)
    }

    func testModifierPressDetectionUsesMatchingFlag() {
        XCTAssertTrue(HotkeyOption.rightCommand.isPressed(in: .maskCommand))
        XCTAssertTrue(HotkeyOption.rightOption.isPressed(in: .maskAlternate))
        XCTAssertTrue(HotkeyOption.rightControl.isPressed(in: .maskControl))
        XCTAssertFalse(HotkeyOption.rightCommand.isPressed(in: []))
    }

    func testLanguageListMatchesAquaPublishedCount() {
        XCTAssertEqual(LanguageOption.all.count, 50)
        XCTAssertEqual(
            LanguageOption.option(for: "he").displayName,
            "Hebrew - עברית"
        )
        XCTAssertEqual(LanguageOption.option(for: "cmn").englishName, "Mandarin")
        XCTAssertEqual(LanguageOption.option(for: "yi").englishName, "Yiddish")
        XCTAssertFalse(LanguageOption.all.contains { $0.code == "zh" })
    }

    func testArbitraryKeyboardChordMatchesItsRecordedModifiers() {
        let hotkey = HotkeyOption.keyboard(
            keyCode: 9,
            modifiers: [.maskCommand, .maskControl],
            keyLabel: "V"
        )

        XCTAssertEqual(hotkey.displayName, "⌃⌘V")
        XCTAssertTrue(
            hotkey.matches(
                keyCode: 9,
                flags: [.maskCommand, .maskControl]
            )
        )
        XCTAssertFalse(hotkey.matches(keyCode: 9, flags: .maskCommand))
    }

    func testLegacyModifierHotkeyStillDecodes() throws {
        let data = try XCTUnwrap("\"MetaRight\"".data(using: .utf8))
        let hotkey = try JSONDecoder().decode(HotkeyOption.self, from: data)

        XCTAssertEqual(hotkey, .rightCommand)
    }

    func testPureModifierChordCanBeRecorded() throws {
        let hotkey = try XCTUnwrap(
            HotkeyOption.modifierChord(
                keyCode: 61,
                modifiers: [
                    .maskCommand,
                    .maskAlternate,
                    .maskControl,
                    .maskShift,
                ]
            )
        )

        XCTAssertTrue(hotkey.isModifierOnly)
        XCTAssertEqual(hotkey.keyCode, 61)
        XCTAssertEqual(hotkey.displayName, "⌃⌥⇧⌘")
        XCTAssertTrue(
            hotkey.isPressed(
                in: [
                    .maskCommand,
                    .maskAlternate,
                    .maskControl,
                    .maskShift,
                ]
            )
        )
    }

    func testAquaShortcutParsesArbitraryKeyAndModifiers() throws {
        let shortcut = try XCTUnwrap(AquaShortcut("Meta+Control+KeyV"))

        XCTAssertEqual(shortcut.keyCode, 9)
        XCTAssertTrue(shortcut.flags.contains(.maskCommand))
        XCTAssertTrue(shortcut.flags.contains(.maskControl))
        XCTAssertFalse(shortcut.isModifierOnly)
    }

    func testAquaShortcutAcceptsModifierOnlyAndBareKeys() throws {
        let modifier = try XCTUnwrap(AquaShortcut("MetaRight"))
        let bareKey = try XCTUnwrap(AquaShortcut("Space"))
        let leftChord = try XCTUnwrap(AquaShortcut("MetaLeft+CapsLock"))

        XCTAssertTrue(modifier.isModifierOnly)
        XCTAssertEqual(modifier.keyCode, 54)
        XCTAssertFalse(bareKey.isModifierOnly)
        XCTAssertEqual(bareKey.keyCode, 49)
        XCTAssertEqual(leftChord.keyCode, 57)
        XCTAssertTrue(leftChord.flags.contains(.maskCommand))
        XCTAssertNil(AquaShortcut("Hyperdrive"))
    }

    func testAquaShortcutMigratesPureModifierChord() throws {
        let shortcut = try XCTUnwrap(
            AquaShortcut("Shift+Meta+Control+Option")
        )

        XCTAssertTrue(shortcut.isModifierOnly)
        XCTAssertEqual(shortcut.hotkey.displayName, "⌃⌥⇧⌘")
        XCTAssertEqual(shortcut.hotkey.keyCode, 58)
    }

    func testAquaShortcutDetectsTriggerConflict() throws {
        let shortcut = try XCTUnwrap(AquaShortcut("MetaRight"))

        XCTAssertTrue(shortcut.conflicts(with: .rightCommand))
        XCTAssertFalse(shortcut.conflicts(with: .rightOption))
    }

    func testLegacyMandarinCodeMigratesToAquaCode() throws {
        let mapping = LanguageMapping(
            languageCode: "zh",
            hotkey: .rightCommand
        )
        let encoded = try JSONEncoder().encode(mapping)
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        var legacyObject = object
        legacyObject["languageCode"] = "zh"
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)

        let decoded = try JSONDecoder().decode(
            LanguageMapping.self,
            from: legacyData
        )

        XCTAssertEqual(decoded.languageCode, "cmn")
    }
}
