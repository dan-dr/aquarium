struct LanguageOption: Hashable, Identifiable {
    let code: String
    let name: String
    let icon: String

    var id: String { code }

    static let all: [LanguageOption] = [
        .init(code: "en", name: "English", icon: "🇺🇸"),
        .init(code: "he", name: "Hebrew", icon: "🇮🇱"),
        .init(code: "ar", name: "Arabic", icon: "🇸🇦"),
        .init(code: "be", name: "Belarusian", icon: "🇧🇾"),
        .init(code: "bn", name: "Bengali", icon: "🇧🇩"),
        .init(code: "bg", name: "Bulgarian", icon: "🇧🇬"),
        .init(code: "yue", name: "Cantonese", icon: "🇭🇰"),
        .init(code: "ca", name: "Catalan", icon: "🏴"),
        .init(code: "cs", name: "Czech", icon: "🇨🇿"),
        .init(code: "da", name: "Danish", icon: "🇩🇰"),
        .init(code: "de", name: "German", icon: "🇩🇪"),
        .init(code: "el", name: "Greek", icon: "🇬🇷"),
        .init(code: "es", name: "Spanish", icon: "🇪🇸"),
        .init(code: "et", name: "Estonian", icon: "🇪🇪"),
        .init(code: "fa", name: "Persian", icon: "🇮🇷"),
        .init(code: "fi", name: "Finnish", icon: "🇫🇮"),
        .init(code: "fr", name: "French", icon: "🇫🇷"),
        .init(code: "gl", name: "Galician", icon: "🇪🇸"),
        .init(code: "hi", name: "Hindi", icon: "🇮🇳"),
        .init(code: "hr", name: "Croatian", icon: "🇭🇷"),
        .init(code: "hu", name: "Hungarian", icon: "🇭🇺"),
        .init(code: "id", name: "Indonesian", icon: "🇮🇩"),
        .init(code: "ga", name: "Irish", icon: "🇮🇪"),
        .init(code: "it", name: "Italian", icon: "🇮🇹"),
        .init(code: "ja", name: "Japanese", icon: "🇯🇵"),
        .init(code: "ko", name: "Korean", icon: "🇰🇷"),
        .init(code: "lt", name: "Lithuanian", icon: "🇱🇹"),
        .init(code: "lv", name: "Latvian", icon: "🇱🇻"),
        .init(code: "ms", name: "Malay", icon: "🇲🇾"),
        .init(code: "mt", name: "Maltese", icon: "🇲🇹"),
        .init(code: "zh", name: "Mandarin", icon: "🇨🇳"),
        .init(code: "mr", name: "Marathi", icon: "🇮🇳"),
        .init(code: "mn", name: "Mongolian", icon: "🇲🇳"),
        .init(code: "nl", name: "Dutch", icon: "🇳🇱"),
        .init(code: "no", name: "Norwegian", icon: "🇳🇴"),
        .init(code: "pl", name: "Polish", icon: "🇵🇱"),
        .init(code: "pt", name: "Portuguese", icon: "🇵🇹"),
        .init(code: "ro", name: "Romanian", icon: "🇷🇴"),
        .init(code: "ru", name: "Russian", icon: "🇷🇺"),
        .init(code: "sl", name: "Slovenian", icon: "🇸🇮"),
        .init(code: "sv", name: "Swedish", icon: "🇸🇪"),
        .init(code: "sw", name: "Swahili", icon: "🇰🇪"),
        .init(code: "ta", name: "Tamil", icon: "🇮🇳"),
        .init(code: "th", name: "Thai", icon: "🇹🇭"),
        .init(code: "tr", name: "Turkish", icon: "🇹🇷"),
        .init(code: "uk", name: "Ukrainian", icon: "🇺🇦"),
        .init(code: "ur", name: "Urdu", icon: "🇵🇰"),
        .init(code: "vi", name: "Vietnamese", icon: "🇻🇳"),
        .init(code: "cy", name: "Welsh", icon: "🏴"),
    ]

    static func option(for code: String) -> LanguageOption {
        all.first { $0.code == code }
            ?? .init(code: code, name: code.uppercased(), icon: "🌐")
    }
}
