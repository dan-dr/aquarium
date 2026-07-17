import AppKit
import SwiftUI

final class AquariumAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct AquariumApp: App {
    @NSApplicationDelegateAdaptor(AquariumAppDelegate.self)
    private var appDelegate
    @StateObject private var model: AquariumModel

    init() {
        let model = AquariumModel()
        _model = StateObject(wrappedValue: model)
        DispatchQueue.main.async {
            model.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(systemName: model.state.symbolName)
                .accessibilityLabel("Aquarium")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(model: model, store: model.settings)
        }
    }
}
