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

    func testPhysicalReleaseClearsRightModifierState() {
        var tracker = ModifierPressTracker()
        let keyCode = HotkeyOption.rightCommand.keyCode

        XCTAssertEqual(
            tracker.transition(keyCode: keyCode, modifierIsPresent: true),
            .pressed
        )
        XCTAssertEqual(
            tracker.transition(keyCode: keyCode, modifierIsPresent: true),
            .released
        )
        XCTAssertEqual(
            tracker.transition(keyCode: keyCode, modifierIsPresent: false),
            .ignored
        )
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

    func testRelayShortcutsUseAquaSupportedFunctionKeys() {
        XCTAssertEqual(
            HotkeyOption.rightCommand.suggestedAquaShortcut,
            "MetaRight+F17"
        )
        XCTAssertEqual(
            HotkeyOption.rightOption.suggestedAquaShortcut,
            "AltRight+F18"
        )
        XCTAssertEqual(
            HotkeyOption.rightControl.suggestedAquaShortcut,
            "ControlRight+F19"
        )
    }

    func testAquaShortcutParsesFunctionKeyAndModifiers() throws {
        let shortcut = try XCTUnwrap(AquaShortcut("MetaRight+Shift+F17"))

        XCTAssertEqual(shortcut.keyCode, 64)
        XCTAssertTrue(shortcut.flags.contains(.maskCommand))
        XCTAssertTrue(shortcut.flags.contains(.maskShift))
        XCTAssertTrue(shortcut.includesTrigger(.rightCommand))
        XCTAssertFalse(shortcut.includesTrigger(.rightOption))
    }

    func testAquaShortcutRejectsModifierOnlyAndUnsupportedKeys() {
        XCTAssertNil(AquaShortcut("MetaRight"))
        XCTAssertNil(AquaShortcut("MetaRight+Space"))
        XCTAssertNil(AquaShortcut("F17"))
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
