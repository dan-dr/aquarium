import Foundation
import XCTest
@testable import Aquarium

final class AquaSettingsFileTests: XCTestCase {
    func testSettingsFileAppliesExactManagedHotkeys() throws {
        let home = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }

        let settingsDirectory = home
            .appendingPathComponent("Library/Application Support/Aqua Voice")
        try FileManager.default.createDirectory(
            at: settingsDirectory,
            withIntermediateDirectories: true
        )
        let settingsURL = settingsDirectory.appendingPathComponent("settings.json")
        let initial: [String: Any] = [
            "streamingMode": "never",
            "hotkeys": [
                ["keys": "MetaRight", "action": "activate"],
                ["keys": "AltRight", "action": "activate"],
                ["keys": "ControlRight", "action": "activate"],
                ["keys": "Escape", "action": "cancel"],
            ],
        ]
        try JSONSerialization.data(withJSONObject: initial).write(to: settingsURL)

        let settings = AquaSettingsFile(homeDirectory: home)
        try settings.apply(LanguageMapping.defaults)

        let data = try Data(contentsOf: settingsURL)
        let updated = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        XCTAssertEqual(updated["streamingMode"] as? String, "always")

        let hotkeys = try XCTUnwrap(updated["hotkeys"] as? [[String: Any]])
        let activationKeys = hotkeys.compactMap { hotkey -> String? in
            hotkey["action"] as? String == "activate"
                ? hotkey["keys"] as? String
                : nil
        }
        XCTAssertEqual(Set(activationKeys), Set(["MetaRight", "AltRight"]))
        XCTAssertTrue(hotkeys.contains { $0["action"] as? String == "cancel" })
        XCTAssertTrue(settings.matches(LanguageMapping.defaults))
    }
}
