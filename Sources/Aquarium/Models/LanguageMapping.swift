import Foundation

struct LanguageMapping: Codable, Equatable, Identifiable {
    var id: UUID
    var languageCode: String
    var hotkey: HotkeyOption
    var icon: String

    init(
        id: UUID = UUID(),
        languageCode: String,
        hotkey: HotkeyOption,
        icon: String
    ) {
        self.id = id
        self.languageCode = languageCode
        self.hotkey = hotkey
        self.icon = icon
    }

    var language: LanguageOption {
        LanguageOption.option(for: languageCode)
    }

    static let defaults: [LanguageMapping] = [
        .init(languageCode: "en", hotkey: .rightCommand, icon: "🇺🇸"),
        .init(languageCode: "he", hotkey: .rightOption, icon: "🇮🇱"),
    ]
}
