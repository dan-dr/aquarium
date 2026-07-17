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

                Text("Set each complex activation hotkey in Aqua Voice first. Aquarium only reads and relays it. It never changes Aqua Voice settings.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Button("Read Aqua Voice Hotkeys") {
                    store.readAquaHotkeys()
                }

                if let notice = store.aquaHotkeyNotice {
                    Text(notice)
                        .font(.callout)
                        .foregroundStyle(.secondary)
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

                if store.hasDuplicateAquaShortcuts {
                    Label(
                        "Choose a different Aqua hotkey for each language.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }

                if store.hasInvalidAquaShortcuts {
                    Label(
                        "Each Aqua hotkey must include its trigger modifier and F13 through F20.",
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
        .frame(width: 660, height: 560)
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
