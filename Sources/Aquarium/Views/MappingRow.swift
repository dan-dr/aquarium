import SwiftUI

struct MappingRow: View {
    @Binding var mapping: LanguageMapping
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Picker("Language", selection: $mapping.languageCode) {
                    ForEach(LanguageOption.all) { language in
                        Text(language.displayName)
                            .tag(language.code)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)

                Picker("Trigger", selection: $mapping.hotkey) {
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

            LabeledContent("Aqua hotkey") {
                TextField("MetaRight+F17", text: $mapping.aquaShortcut)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding(.vertical, 3)
    }
}
