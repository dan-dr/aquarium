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

        XCTAssertTrue(tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: true))
        XCTAssertFalse(tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: true))
        XCTAssertFalse(tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: false))
        XCTAssertTrue(tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: true))
    }

    func testLanguageListMatchesAquaPublishedCount() {
        XCTAssertEqual(LanguageOption.all.count, 49)
        XCTAssertFalse(LanguageOption.all.contains { $0.code == "sk" })
    }
}
