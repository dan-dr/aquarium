import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let maximumMappings = 3
    static let suggestedAquaHotkey = HotkeyOption.suggestedAquaRelay

    @Published var mappings: [LanguageMapping] {
        didSet { save() }
    }
    @Published var aquaHotkey: HotkeyOption {
        didSet { saveAquaHotkey() }
    }

    private let defaults: UserDefaults
    private let storageKey = "languageMappings"
    private let aquaHotkeyStorageKey = "aquaHotkey"
    private let legacyAquaShortcutStorageKey = "aquaShortcut"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let data = defaults.data(forKey: aquaHotkeyStorageKey),
            let stored = try? JSONDecoder().decode(
                HotkeyOption.self,
                from: data
            )
        {
            aquaHotkey = stored
        } else if
            let legacy = defaults.string(
                forKey: legacyAquaShortcutStorageKey
            ),
            let parsed = AquaShortcut(legacy)
        {
            aquaHotkey = parsed.hotkey
        } else {
            aquaHotkey = Self.suggestedAquaHotkey
        }
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
        Set(mappings.map(\.hotkey.id)).count != mappings.count
    }

    var hasAquaHotkeyConflict: Bool {
        mappings.contains { aquaHotkey.id == $0.hotkey.id }
    }

    var hasConfigurationErrors: Bool {
        hasDuplicateHotkeys
            || hasAquaHotkeyConflict
    }

    func addMapping() {
        guard canAddMapping else { return }
        let usedHotkeys = Set(mappings.map(\.hotkey.id))
        guard let hotkey = HotkeyOption.suggestedTriggers.first(where: {
            !usedHotkeys.contains($0.id)
        }) else { return }

        let usedLanguages = Set(mappings.map(\.languageCode))
        let language = LanguageOption.all.first(where: {
            !usedLanguages.contains($0.code)
        }) ?? LanguageOption.all[0]
        mappings.append(
            .init(
                languageCode: language.code,
                hotkey: hotkey
            )
        )
    }

    func removeMapping(id: UUID) {
        guard mappings.count > 1 else { return }
        mappings.removeAll { $0.id == id }
    }

    func reset() {
        mappings = LanguageMapping.defaults
        aquaHotkey = Self.suggestedAquaHotkey
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(mappings) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func saveAquaHotkey() {
        guard let data = try? JSONEncoder().encode(aquaHotkey) else { return }
        defaults.set(data, forKey: aquaHotkeyStorageKey)
    }

}
