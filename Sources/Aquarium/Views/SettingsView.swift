import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AquariumModel
    @ObservedObject var store: SettingsStore

    var body: some View {
        Form {
            Section("Aqua Voice") {
                LabeledContent("Status") {
                    Label(model.state.label, systemImage: model.state.symbolName)
                        .foregroundStyle(statusColor)
                }

                Text("Set one activation hotkey in Aqua Voice, then record the same hotkey here. A modifier-only chord avoids typing in other apps.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Aqua hotkey")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HotkeyRecorder(hotkey: $store.aquaHotkey)
                }

                if store.hasAquaHotkeyConflict {
                    Label(
                        "The Aqua hotkey must be different from every language hotkey.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.callout)
                    .foregroundStyle(.orange)
                }
            }

            Section("Languages") {
                ForEach($store.mappings) { $mapping in
                    MappingRow(
                        mapping: $mapping,
                        canRemove: store.mappings.count > 1,
                        onRemove: { store.removeMapping(id: mapping.id) }
                    )
                }

                if store.hasDuplicateHotkeys {
                    Label(
                        "Choose a different hotkey for each language.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }

                HStack {
                    Button("Add Language", systemImage: "plus") {
                        store.addMapping()
                    }
                    .disabled(!store.canAddMapping)

                    Spacer()

                    Button("Apply") {
                        model.applyConfiguration()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(store.hasConfigurationErrors || model.isApplying)
                }
            }

            Section("General") {
                Toggle(
                    "Launch Aquarium at login",
                    isOn: Binding(
                        get: { model.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )

                Button("Restore Defaults") {
                    store.reset()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 640, height: 520)
        .navigationTitle("Aquarium Settings")
    }

    private var statusColor: Color {
        switch model.state {
        case .ready: .green
        case .starting: .secondary
        case .permissionRequired, .unavailable: .orange
        }
    }
}
