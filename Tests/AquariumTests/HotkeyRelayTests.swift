import CoreGraphics
import XCTest
@testable import Aquarium

final class HotkeyRelayTests: XCTestCase {
    func testLanguageChangesBeforeRelayPressAndRelease() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: RecordingLanguageSelector(recorder: recorder),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        relay.update(
            mappings: LanguageMapping.defaults,
            aquaShortcut: "Meta+Alt+Control+Shift+F17"
        )

        relay.handle(
            type: .flagsChanged,
            keyCode: HotkeyOption.rightOption.keyCode,
            flags: .maskAlternate
        )
        relay.handle(
            type: .flagsChanged,
            keyCode: HotkeyOption.rightOption.keyCode,
            flags: .maskAlternate
        )
        relay.waitUntilIdle()

        XCTAssertEqual(
            recorder.events,
            [
                "language:he",
                "down:Meta+Alt+Control+Shift+F17",
                "up:Meta+Alt+Control+Shift+F17",
            ]
        )
    }

    func testArbitraryKeyboardChordRelaysPressAndRelease() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: RecordingLanguageSelector(recorder: recorder),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        let trigger = HotkeyOption.keyboard(
            keyCode: 0,
            modifiers: [.maskCommand, .maskShift],
            keyLabel: "A"
        )
        relay.update(
            mappings: [.init(languageCode: "en", hotkey: trigger)],
            aquaShortcut: "Control+F18"
        )

        relay.handle(
            type: .keyDown,
            keyCode: 0,
            flags: [.maskCommand, .maskShift]
        )
        relay.handle(
            type: .keyUp,
            keyCode: 0,
            flags: [.maskCommand, .maskShift]
        )
        relay.waitUntilIdle()

        XCTAssertEqual(
            recorder.events,
            ["language:en", "down:Control+F18", "up:Control+F18"]
        )
    }

    func testRepeatedKeyDownDoesNotStartASecondRelay() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: RecordingLanguageSelector(recorder: recorder),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        let trigger = HotkeyOption.keyboard(
            keyCode: 49,
            modifiers: .maskControl,
            keyLabel: "Space"
        )
        relay.update(
            mappings: [.init(languageCode: "he", hotkey: trigger)],
            aquaShortcut: "F17"
        )

        relay.handle(
            type: .keyDown,
            keyCode: 49,
            flags: .maskControl
        )
        relay.handle(
            type: .keyDown,
            keyCode: 49,
            flags: .maskControl,
            isRepeat: true
        )
        relay.handle(type: .keyUp, keyCode: 49, flags: .maskControl)
        relay.waitUntilIdle()

        XCTAssertEqual(
            recorder.events,
            ["language:he", "down:F17", "up:F17"]
        )
    }
}

private final class RelayRecorder {
    var events: [String] = []
}

private struct RecordingLanguageSelector: AquaLanguageSelecting {
    let recorder: RelayRecorder

    func setLanguage(_ languageCode: String) throws {
        recorder.events.append("language:\(languageCode)")
    }
}

private struct RecordingHotkeyPoster: AquaHotkeyPosting {
    let recorder: RelayRecorder

    func post(shortcut: String, keyDown: Bool) throws {
        recorder.events.append(
            "\(keyDown ? "down" : "up"):\(shortcut)"
        )
    }
}
