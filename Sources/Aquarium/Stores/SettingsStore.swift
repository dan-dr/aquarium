import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let maximumMappings = 3
    static let suggestedAquaShortcut = "Meta+Alt+Control+Shift+F17"

    @Published var mappings: [LanguageMapping] {
        didSet { save() }
    }
    @Published var aquaShortcut: String {
        didSet {
            defaults.set(aquaShortcut, forKey: aquaShortcutStorageKey)
        }
    }

    private let defaults: UserDefaults
    private let storageKey = "languageMappings"
    private let aquaShortcutStorageKey = "aquaShortcut"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedAquaShortcut = defaults
            .string(forKey: aquaShortcutStorageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let storedAquaShortcut, !storedAquaShortcut.isEmpty {
            aquaShortcut = storedAquaShortcut
        } else {
            aquaShortcut = Self.suggestedAquaShortcut
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

    var hasInvalidAquaShortcut: Bool {
        AquaShortcut(aquaShortcut) == nil
    }

    var hasAquaHotkeyConflict: Bool {
        guard let shortcut = AquaShortcut(aquaShortcut) else { return false }
        return mappings.contains { shortcut.conflicts(with: $0.hotkey) }
    }

    var hasConfigurationErrors: Bool {
        hasDuplicateHotkeys
            || hasInvalidAquaShortcut
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
        aquaShortcut = Self.suggestedAquaShortcut
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(mappings) else { return }
        defaults.set(data, forKey: storageKey)
    }

}
