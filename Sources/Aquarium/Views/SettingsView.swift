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

                Text("Hold a configured key for streaming dictation. Double-tap it for Aqua Voice hands-free mode.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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
                    .disabled(store.hasDuplicateHotkeys || model.isApplying)
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
        .frame(width: 590, height: 440)
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
