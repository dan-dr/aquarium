import SwiftUI

struct MappingRow: View {
    @Binding var mapping: LanguageMapping
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Icon", text: $mapping.icon)
                .multilineTextAlignment(.center)
                .frame(width: 44)
                .accessibilityLabel("Language icon")

            Picker("Language", selection: $mapping.languageCode) {
                ForEach(LanguageOption.all) { language in
                    Text("\(language.icon) \(language.name)")
                        .tag(language.code)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .onChange(of: mapping.languageCode) { _, code in
                mapping.icon = LanguageOption.option(for: code).icon
            }

            Picker("Hotkey", selection: $mapping.hotkey) {
                ForEach(HotkeyOption.allCases) { hotkey in
                    Text("\(hotkey.glyph) \(hotkey.displayName)")
                        .tag(hotkey)
                }
            }
            .labelsHidden()
            .frame(width: 170)

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.borderless)
            .disabled(!canRemove)
            .accessibilityLabel("Remove language")
        }
    }
}
