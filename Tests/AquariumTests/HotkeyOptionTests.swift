import CoreGraphics
import Testing
@testable import Aquarium

@Test func rightModifierKeyCodesMatchMacOS() {
    #expect(HotkeyOption.rightCommand.keyCode == 54)
    #expect(HotkeyOption.rightOption.keyCode == 61)
    #expect(HotkeyOption.rightControl.keyCode == 62)
}

@Test func modifierPressDetectionUsesMatchingFlag() {
    #expect(HotkeyOption.rightCommand.isPressed(in: .maskCommand))
    #expect(HotkeyOption.rightOption.isPressed(in: .maskAlternate))
    #expect(HotkeyOption.rightControl.isPressed(in: .maskControl))
    #expect(!HotkeyOption.rightCommand.isPressed(in: []))
}

@Test func physicalReleaseClearsRightModifierState() {
    var tracker = ModifierPressTracker()
    let keyCode = HotkeyOption.rightCommand.keyCode

    let firstPress = tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: true)
    let repeatedPress = tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: true)
    let release = tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: false)
    let secondPress = tracker.shouldActivate(keyCode: keyCode, isPhysicallyPressed: true)

    #expect(firstPress)
    #expect(!repeatedPress)
    #expect(!release)
    #expect(secondPress)
}

@Test func languageListMatchesAquaPublishedCount() {
    #expect(LanguageOption.all.count == 49)
    #expect(!LanguageOption.all.contains { $0.code == "sk" })
}
