import Foundation

enum AquaSettingsError: LocalizedError {
    case missingSettings
    case invalidSettings

    var errorDescription: String? {
        switch self {
        case .missingSettings:
            "Run Aqua Voice once before configuring Aquarium."
        case .invalidSettings:
            "Aqua Voice's settings file is not valid JSON."
        }
    }
}

struct AquaSettingsFile {
    let url: URL

    init(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        url = homeDirectory
            .appendingPathComponent("Library/Application Support/Aqua Voice")
            .appendingPathComponent("settings.json")
    }

    func matches(_ mappings: [LanguageMapping]) -> Bool {
        guard let object = try? readObject() else { return false }
        guard object["streamingMode"] as? String == "always" else {
            return false
        }

        let configured = activationHotkeys(in: object)
        let expected = Set(mappings.map { $0.hotkey.rawValue })
        let managed = Set(HotkeyOption.allCases.map(\.rawValue))
        return configured.intersection(managed) == expected
    }

    func apply(_ mappings: [LanguageMapping]) throws {
        var object = try readObject()
        let managed = Set(HotkeyOption.allCases.map(\.rawValue))
        var hotkeys = object["hotkeys"] as? [[String: Any]] ?? []
        hotkeys.removeAll { hotkey in
            hotkey["action"] as? String == "activate"
                && managed.contains(hotkey["keys"] as? String ?? "")
        }
        hotkeys.insert(
            contentsOf: mappings.map {
                ["keys": $0.hotkey.rawValue, "action": "activate"]
            },
            at: 0
        )
        object["hotkeys"] = hotkeys
        object["streamingMode"] = "always"

        try createBackupIfNeeded()
        let data = try JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: url, options: .atomic)
    }

    private func activationHotkeys(in object: [String: Any]) -> Set<String> {
        let hotkeys = object["hotkeys"] as? [[String: Any]] ?? []
        return Set(hotkeys.compactMap { hotkey in
            guard hotkey["action"] as? String == "activate" else {
                return nil
            }
            return hotkey["keys"] as? String
        })
    }

    private func readObject() throws -> [String: Any] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AquaSettingsError.missingSettings
        }
        let data = try Data(contentsOf: url)
        guard let object = try JSONSerialization.jsonObject(
            with: data
        ) as? [String: Any] else {
            throw AquaSettingsError.invalidSettings
        }
        return object
    }

    private func createBackupIfNeeded() throws {
        let backup = url.deletingLastPathComponent()
            .appendingPathComponent("settings.aquarium-backup.json")
        guard !FileManager.default.fileExists(atPath: backup.path) else {
            return
        }
        try FileManager.default.copyItem(at: url, to: backup)
    }
}
