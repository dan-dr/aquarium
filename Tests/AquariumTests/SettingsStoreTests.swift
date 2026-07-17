import Foundation
import XCTest
@testable import Aquarium

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testBlankStoredAquaHotkeyUsesEditableSuggestion() throws {
        let suiteName = "AquariumTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("", forKey: "aquaShortcut")

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(
            store.aquaShortcut,
            SettingsStore.suggestedAquaShortcut
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

        store.aquaShortcut = "MetaRight"

        XCTAssertTrue(store.hasAquaHotkeyConflict)
        XCTAssertTrue(store.hasConfigurationErrors)
    }
}
