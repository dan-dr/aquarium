import SwiftUI

struct MappingRow: View {
    @Binding var mapping: LanguageMapping
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Choose language")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Choose language", selection: $mapping.languageCode) {
                    ForEach(LanguageOption.all) { language in
                        Text(language.displayName)
                            .tag(language.code)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Choose hotkey")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HotkeyRecorder(hotkey: $mapping.hotkey)
            }
            .frame(maxWidth: .infinity)

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "minus.circle.fill")
            }
            .buttonStyle(.borderless)
            .disabled(!canRemove)
            .accessibilityLabel("Remove language")
            .padding(.bottom, 5)
        }
        .padding(.vertical, 5)
    }
}
