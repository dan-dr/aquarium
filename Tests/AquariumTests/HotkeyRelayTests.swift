import CoreGraphics
import XCTest
@testable import Aquarium

final class HotkeyRelayTests: XCTestCase {
    func testInjectedRelayEventsCarryAquariumMarker() throws {
        let event = try XCTUnwrap(
            CGEvent(
                keyboardEventSource: nil,
                virtualKey: 64,
                keyDown: true
            )
        )

        XCTAssertFalse(AquariumInjectedEvent.matches(event))
        AquariumInjectedEvent.mark(event)
        XCTAssertTrue(AquariumInjectedEvent.matches(event))
    }

    func testPureModifierRelayEmitsEveryPhysicalTransition() throws {
        let hotkey = try XCTUnwrap(
            HotkeyOption.modifierChord(
                keyCode: 58,
                modifiers: [
                    .maskCommand,
                    .maskAlternate,
                    .maskControl,
                    .maskShift,
                ]
            )
        )

        let down = AquaHotkeyEventSequence.steps(
            for: hotkey,
            keyDown: true
        )
        let up = AquaHotkeyEventSequence.steps(
            for: hotkey,
            keyDown: false
        )

        XCTAssertEqual(down.map(\.keyCode), [55, 58, 59, 56])
        XCTAssertEqual(
            down.map(\.flags),
            [
                [.maskCommand],
                [.maskCommand, .maskAlternate],
                [.maskCommand, .maskAlternate, .maskControl],
                [
                    .maskCommand,
                    .maskAlternate,
                    .maskControl,
                    .maskShift,
                ],
            ]
        )
        XCTAssertEqual(up.map(\.keyCode), [56, 59, 58, 55])
        XCTAssertEqual(up.last?.flags, [])
        XCTAssertTrue((down + up).allSatisfy { $0.type == .flagsChanged })
    }

    func testMatchingLanguageTriggerIsConsumed() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: RecordingLanguageSelector(recorder: recorder),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        relay.update(
            mappings: LanguageMapping.defaults,
            aquaHotkey: .suggestedAquaRelay
        )

        XCTAssertTrue(
            relay.handle(
                type: .flagsChanged,
                keyCode: HotkeyOption.rightCommand.keyCode,
                flags: .maskCommand
            )
        )
        XCTAssertFalse(
            relay.handle(
                type: .keyDown,
                keyCode: 0,
                flags: []
            )
        )
        relay.resetPressedKeys()
        relay.waitUntilIdle()
    }

    func testLanguageChangesBeforeRelayPressAndRelease() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: RecordingLanguageSelector(recorder: recorder),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        relay.update(
            mappings: LanguageMapping.defaults,
            aquaHotkey: .suggestedAquaRelay
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
                "down:⌃⌥⇧⌘F17",
                "up:⌃⌥⇧⌘F17",
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
            aquaHotkey: .keyboard(
                keyCode: 79,
                modifiers: .maskControl,
                keyLabel: "F18"
            )
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
            ["language:en", "down:⌃F18", "up:⌃F18"]
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
            aquaHotkey: .keyboard(
                keyCode: 64,
                modifiers: [],
                keyLabel: "F17"
            )
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

    func testDoubleTapReusesFreshLanguageSelection() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: RecordingLanguageSelector(recorder: recorder),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        relay.update(
            mappings: LanguageMapping.defaults,
            aquaHotkey: .suggestedAquaRelay
        )

        for _ in 0..<2 {
            relay.handle(
                type: .flagsChanged,
                keyCode: HotkeyOption.rightCommand.keyCode,
                flags: .maskCommand
            )
            relay.handle(
                type: .flagsChanged,
                keyCode: HotkeyOption.rightCommand.keyCode,
                flags: []
            )
        }
        relay.waitUntilIdle()

        XCTAssertEqual(
            recorder.events,
            [
                "language:en",
                "down:⌃⌥⇧⌘F17",
                "up:⌃⌥⇧⌘F17",
                "down:⌃⌥⇧⌘F17",
                "up:⌃⌥⇧⌘F17",
            ]
        )
    }

    func testRelayStillStartsWhenLanguageSelectionFails() {
        let recorder = RelayRecorder()
        let relay = HotkeyRelay(
            languageSelector: FailingLanguageSelector(),
            hotkeyPoster: RecordingHotkeyPoster(recorder: recorder)
        )
        relay.update(
            mappings: LanguageMapping.defaults,
            aquaHotkey: .suggestedAquaRelay
        )

        relay.handle(
            type: .flagsChanged,
            keyCode: HotkeyOption.rightCommand.keyCode,
            flags: .maskCommand
        )
        relay.handle(
            type: .flagsChanged,
            keyCode: HotkeyOption.rightCommand.keyCode,
            flags: []
        )
        relay.waitUntilIdle()

        XCTAssertEqual(
            recorder.events,
            ["down:⌃⌥⇧⌘F17", "up:⌃⌥⇧⌘F17"]
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

private struct FailingLanguageSelector: AquaLanguageSelecting {
    struct Failure: Error {}

    func setLanguage(_: String) throws {
        throw Failure()
    }
}

private struct RecordingHotkeyPoster: AquaHotkeyPosting {
    let recorder: RelayRecorder

    func post(hotkey: HotkeyOption, keyDown: Bool) throws {
        recorder.events.append(
            "\(keyDown ? "down" : "up"):\(hotkey.displayName)"
        )
    }
}
