import Foundation
import Testing
@testable import Aquarium

@MainActor
@Test func settingsStoreCapsMappingsAtThree() throws {
    let suiteName = "AquariumTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let store = SettingsStore(defaults: defaults)
    store.addMapping()
    store.addMapping()

    #expect(store.mappings.count == 3)
    #expect(!store.canAddMapping)
    #expect(!store.hasDuplicateHotkeys)
}
