import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let maximumMappings = 3

    @Published var mappings: [LanguageMapping] {
        didSet { save() }
    }
    @Published private(set) var aquaHotkeyNotice: String?

    private let defaults: UserDefaults
    private let aquaSettingsFile: AquaSettingsFile
    private let storageKey = "languageMappings"

    init(
        defaults: UserDefaults = .standard,
        aquaSettingsFile: AquaSettingsFile = .init()
    ) {
        self.defaults = defaults
        self.aquaSettingsFile = aquaSettingsFile
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
            applyDetectedAquaHotkeys(showNotice: false)
        }
    }

    var canAddMapping: Bool {
        mappings.count < Self.maximumMappings
    }

    var hasDuplicateHotkeys: Bool {
        Set(mappings.map(\.hotkey)).count != mappings.count
    }

    var hasDuplicateAquaShortcuts: Bool {
        Set(mappings.map { $0.aquaShortcut.lowercased() }).count
            != mappings.count
    }

    var hasInvalidAquaShortcuts: Bool {
        mappings.contains { mapping in
            guard let shortcut = AquaShortcut(mapping.aquaShortcut) else {
                return true
            }
            return !shortcut.includesTrigger(mapping.hotkey)
        }
    }

    var hasConfigurationErrors: Bool {
        hasDuplicateHotkeys
            || hasDuplicateAquaShortcuts
            || hasInvalidAquaShortcuts
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
                aquaShortcut: hotkey.suggestedAquaShortcut
            )
        )
    }

    func removeMapping(id: UUID) {
        guard mappings.count > 1 else { return }
        mappings.removeAll { $0.id == id }
    }

    func reset() {
        mappings = LanguageMapping.defaults
        applyDetectedAquaHotkeys(showNotice: false)
    }

    func readAquaHotkeys() {
        applyDetectedAquaHotkeys(showNotice: true)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(mappings) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func applyDetectedAquaHotkeys(showNotice: Bool) {
        do {
            let shortcuts = try aquaSettingsFile.activationShortcuts()
            guard !shortcuts.isEmpty else {
                if showNotice {
                    aquaHotkeyNotice = "No Aqua Voice activation hotkeys found."
                }
                return
            }
            for index in mappings.indices {
                guard shortcuts.indices.contains(index) else { break }
                mappings[index].aquaShortcut = shortcuts[index]
            }
            if showNotice {
                aquaHotkeyNotice = "Read \(min(shortcuts.count, mappings.count)) Aqua Voice hotkey(s)."
            }
        } catch {
            if showNotice {
                aquaHotkeyNotice = error.localizedDescription
            }
        }
    }
}
