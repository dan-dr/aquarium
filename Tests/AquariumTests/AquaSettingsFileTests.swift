import Foundation
import XCTest
@testable import Aquarium

final class AquaSettingsFileTests: XCTestCase {
    func testSettingsFileReadsActivationHotkeysWithoutChangingFile() throws {
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
                ["keys": "MetaRight+F17", "action": "activate"],
                ["keys": "AltRight+F18", "action": "activate"],
                ["keys": "Escape", "action": "cancel"],
            ],
        ]
        let initialData = try JSONSerialization.data(
            withJSONObject: initial,
            options: [.prettyPrinted, .sortedKeys]
        )
        try initialData.write(to: settingsURL)

        let settings = AquaSettingsFile(homeDirectory: home)
        XCTAssertEqual(
            try settings.activationShortcuts(),
            ["MetaRight+F17", "AltRight+F18"]
        )
        XCTAssertEqual(try Data(contentsOf: settingsURL), initialData)
    }
}
