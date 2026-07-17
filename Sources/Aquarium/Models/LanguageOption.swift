struct LanguageOption: Hashable, Identifiable {
    let code: String
    let englishName: String
    let nativeName: String?

    var id: String { code }

    var displayName: String {
        guard let nativeName else { return englishName }
        return "\(englishName) - \(nativeName)"
    }

    static let all: [LanguageOption] = [
        .init(code: "ar", englishName: "Arabic", nativeName: "العربية"),
        .init(code: "be", englishName: "Belarusian", nativeName: "Беларуская"),
        .init(code: "bn", englishName: "Bengali", nativeName: "বাংলা"),
        .init(code: "bg", englishName: "Bulgarian", nativeName: "Български"),
        .init(code: "yue", englishName: "Cantonese", nativeName: "粵語"),
        .init(code: "ca", englishName: "Catalan", nativeName: "Català"),
        .init(code: "hr", englishName: "Croatian", nativeName: "Hrvatski"),
        .init(code: "cs", englishName: "Czech", nativeName: "Čeština"),
        .init(code: "da", englishName: "Danish", nativeName: "Dansk"),
        .init(code: "nl", englishName: "Dutch", nativeName: "Nederlands"),
        .init(code: "en", englishName: "English", nativeName: nil),
        .init(code: "et", englishName: "Estonian", nativeName: "Eesti"),
        .init(code: "fi", englishName: "Finnish", nativeName: "Suomi"),
        .init(code: "fr", englishName: "French", nativeName: "Français"),
        .init(code: "gl", englishName: "Galician", nativeName: "Galego"),
        .init(code: "de", englishName: "German", nativeName: "Deutsch"),
        .init(code: "el", englishName: "Greek", nativeName: "Ελληνικά"),
        .init(code: "he", englishName: "Hebrew", nativeName: "עברית"),
        .init(code: "hi", englishName: "Hindi", nativeName: "हिन्दी"),
        .init(code: "hu", englishName: "Hungarian", nativeName: "Magyar"),
        .init(code: "id", englishName: "Indonesian", nativeName: "Bahasa Indonesia"),
        .init(code: "ga", englishName: "Irish", nativeName: "Gaeilge"),
        .init(code: "it", englishName: "Italian", nativeName: "Italiano"),
        .init(code: "ja", englishName: "Japanese", nativeName: "日本語"),
        .init(code: "ko", englishName: "Korean", nativeName: "한국어"),
        .init(code: "lv", englishName: "Latvian", nativeName: "Latviešu"),
        .init(code: "lt", englishName: "Lithuanian", nativeName: "Lietuvių"),
        .init(code: "ms", englishName: "Malay", nativeName: "Bahasa Melayu"),
        .init(code: "mt", englishName: "Maltese", nativeName: "Malti"),
        .init(code: "cmn", englishName: "Mandarin", nativeName: "普通话"),
        .init(code: "mr", englishName: "Marathi", nativeName: "मराठी"),
        .init(code: "mn", englishName: "Mongolian", nativeName: "Монгол"),
        .init(code: "no", englishName: "Norwegian", nativeName: "Norsk"),
        .init(code: "fa", englishName: "Persian", nativeName: "فارسی"),
        .init(code: "pl", englishName: "Polish", nativeName: "Polski"),
        .init(code: "pt", englishName: "Portuguese", nativeName: "Português"),
        .init(code: "ro", englishName: "Romanian", nativeName: "Română"),
        .init(code: "ru", englishName: "Russian", nativeName: "Русский"),
        .init(code: "sl", englishName: "Slovenian", nativeName: "Slovenščina"),
        .init(code: "es", englishName: "Spanish", nativeName: "Español"),
        .init(code: "sw", englishName: "Swahili", nativeName: "Kiswahili"),
        .init(code: "sv", englishName: "Swedish", nativeName: "Svenska"),
        .init(code: "ta", englishName: "Tamil", nativeName: "தமிழ்"),
        .init(code: "th", englishName: "Thai", nativeName: "ไทย"),
        .init(code: "tr", englishName: "Turkish", nativeName: "Türkçe"),
        .init(code: "uk", englishName: "Ukrainian", nativeName: "Українська"),
        .init(code: "ur", englishName: "Urdu", nativeName: "اردو"),
        .init(code: "vi", englishName: "Vietnamese", nativeName: "Tiếng Việt"),
        .init(code: "cy", englishName: "Welsh", nativeName: "Cymraeg"),
        .init(code: "yi", englishName: "Yiddish", nativeName: "ייִדיש"),
    ]

    static func option(for code: String) -> LanguageOption {
        all.first { $0.code == code }
            ?? .init(code: code, englishName: code.uppercased(), nativeName: nil)
    }
}
