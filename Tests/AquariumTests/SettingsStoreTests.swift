import Foundation
import XCTest
@testable import Aquarium

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testBlankStoredAquaHotkeyUsesRecordedSuggestion() throws {
        let suiteName = "AquariumTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("", forKey: "aquaShortcut")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(
            store.aquaHotkey,
            SettingsStore.suggestedAquaHotkey
        )
        XCTAssertFalse(store.hasConfigurationErrors)
    }

    func testSettingsStoreCapsMappingsAtThree() throws {
        let suiteName = "AquariumTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.addMapping()
        store.addMapping()

        XCTAssertEqual(store.mappings.count, 3)
        XCTAssertFalse(store.canAddMapping)
        XCTAssertFalse(store.hasDuplicateHotkeys)
    }

    func testRejectsAquaHotkeyThatConflictsWithLanguageTrigger() throws {
        let suiteName = "AquariumTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = SettingsStore(defaults: defaults)

        store.aquaHotkey = .rightCommand

        XCTAssertTrue(store.hasAquaHotkeyConflict)
        XCTAssertTrue(store.hasConfigurationErrors)
    }

    func testLegacyTextAquaHotkeyMigratesToRecordedHotkey() throws {
        let suiteName = "AquariumTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("Control+F18", forKey: "aquaShortcut")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.aquaHotkey.displayName, "⌃F18")
        XCTAssertEqual(store.aquaHotkey.keyCode, 79)
    }

    func testLegacyPureModifierAquaHotkeyMigrates() throws {
        let suiteName = "AquariumTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(
            "Shift+Meta+Control+Option",
            forKey: "aquaShortcut"
        )

        let store = SettingsStore(defaults: defaults)

        XCTAssertTrue(store.aquaHotkey.isModifierOnly)
        XCTAssertEqual(store.aquaHotkey.displayName, "⌃⌥⇧⌘")
    }
}
