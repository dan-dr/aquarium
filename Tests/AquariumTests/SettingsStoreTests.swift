import Foundation
import XCTest
@testable import Aquarium

@MainActor
final class SettingsStoreTests: XCTestCase {
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
}
