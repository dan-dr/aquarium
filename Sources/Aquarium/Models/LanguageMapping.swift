import Foundation

struct LanguageMapping: Codable, Equatable, Identifiable {
    var id: UUID
    var languageCode: String
    var hotkey: HotkeyOption

    init(
        id: UUID = UUID(),
        languageCode: String,
        hotkey: HotkeyOption
    ) {
        self.id = id
        self.languageCode = languageCode
        self.hotkey = hotkey
    }

    var language: LanguageOption {
        LanguageOption.option(for: languageCode)
    }

    static let defaults: [LanguageMapping] = [
        .init(languageCode: "en", hotkey: .rightCommand),
        .init(languageCode: "he", hotkey: .rightOption),
    ]

    enum CodingKeys: String, CodingKey {
        case id
        case languageCode
        case hotkey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let storedLanguageCode = try container.decode(
            String.self,
            forKey: .languageCode
        )
        languageCode = storedLanguageCode == "zh" ? "cmn" : storedLanguageCode
        hotkey = try container.decode(HotkeyOption.self, forKey: .hotkey)
    }
}
