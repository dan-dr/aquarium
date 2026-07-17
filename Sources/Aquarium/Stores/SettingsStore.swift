import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let maximumMappings = 3

    @Published var mappings: [LanguageMapping] {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let storageKey = "languageMappings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let data = defaults.data(forKey: storageKey),
            let stored = try? JSONDecoder().decode(
                [LanguageMapping].self,
                from: data
            ),
            !stored.isEmpty
        {
            mappings = Array(stored.prefix(Self.maximumMappings))
        } else {
            mappings = LanguageMapping.defaults
        }
    }

    var canAddMapping: Bool {
        mappings.count < Self.maximumMappings
    }

    var hasDuplicateHotkeys: Bool {
        Set(mappings.map(\.hotkey)).count != mappings.count
    }

    func addMapping() {
        guard canAddMapping else { return }
        let usedHotkeys = Set(mappings.map(\.hotkey))
        guard let hotkey = HotkeyOption.allCases.first(where: {
            !usedHotkeys.contains($0)
        }) else { return }

        let usedLanguages = Set(mappings.map(\.languageCode))
        let language = LanguageOption.all.first(where: {
            !usedLanguages.contains($0.code)
        }) ?? LanguageOption.all[0]
        mappings.append(
            .init(
                languageCode: language.code,
                hotkey: hotkey,
                icon: language.icon
            )
        )
    }

    func removeMapping(id: UUID) {
        guard mappings.count > 1 else { return }
        mappings.removeAll { $0.id == id }
    }

    func reset() {
        mappings = LanguageMapping.defaults
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(mappings) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
