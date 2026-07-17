import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AquariumModel

    var body: some View {
        Label(model.state.label, systemImage: model.state.symbolName)
            .foregroundStyle(statusColor)

        Divider()

        ForEach(model.settings.mappings) { mapping in
            Button {
                model.selectLanguage(mapping)
            } label: {
                Text("\(mapping.icon) \(mapping.language.name)  \(mapping.hotkey.glyph)")
            }
        }

        Divider()

        Button("Restart Aqua Voice") {
            model.applyConfiguration(forceRestart: true)
        }
        .disabled(model.isApplying)

        SettingsLink {
            Label("Settings…", systemImage: "gearshape")
        }

        Divider()

        Button("Quit Aquarium") {
            NSApplication.shared.terminate(nil)
        }
    }

    private var statusColor: Color {
        switch model.state {
        case .ready: .green
        case .starting: .secondary
        case .permissionRequired, .unavailable: .orange
        }
    }
}
