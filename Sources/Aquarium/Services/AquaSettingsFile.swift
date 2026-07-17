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

    func activationShortcuts() throws -> [String] {
        let object = try readObject()
        let hotkeys = object["hotkeys"] as? [[String: Any]] ?? []
        return hotkeys.compactMap { hotkey in
            guard hotkey["action"] as? String == "activate" else {
                return nil
            }
            return hotkey["keys"] as? String
        }
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

}
