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
        relay.update(mappings: LanguageMapping.defaults)

        relay.handle(
            keyCode: HotkeyOption.rightOption.keyCode,
            flags: .maskAlternate
        )
        relay.handle(
            keyCode: HotkeyOption.rightOption.keyCode,
            flags: .maskAlternate
        )
        relay.waitUntilIdle()

        XCTAssertEqual(
            recorder.events,
            [
                "language:he",
                "down:AltRight+F18",
                "up:AltRight+F18",
            ]
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
