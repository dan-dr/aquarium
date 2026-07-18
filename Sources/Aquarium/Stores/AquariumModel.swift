import Combine
import Foundation

@MainActor
final class AquariumModel: ObservableObject {
    let settings: SettingsStore

    @Published private(set) var state: AquariumState = .starting
    @Published private(set) var isApplying = false
    @Published private(set) var launchAtLogin = LoginItemService.isEnabled

    private let coordinator: AquaCoordinator
    private var hasStarted = false

    init(
        settings: SettingsStore? = nil,
        coordinator: AquaCoordinator = .init()
    ) {
        self.settings = settings ?? SettingsStore()
        self.coordinator = coordinator
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        applyConfiguration()
    }

    func applyConfiguration(forceRestart: Bool = false) {
        guard !isApplying else { return }
        guard !settings.hasConfigurationErrors else {
            state = .unavailable("Fix the hotkey settings before applying.")
            return
        }

        isApplying = true
        state = .starting
        let mappings = settings.mappings
        let aquaHotkey = settings.aquaHotkey
        let coordinator = coordinator

        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try coordinator.apply(
                        mappings: mappings,
                        aquaHotkey: aquaHotkey,
                        forceRestart: forceRestart
                    )
                }.value
                state = .ready
            } catch let error as ShortcutMonitorError {
                state = .permissionRequired(
                    error.localizedDescription
                )
            } catch {
                state = .unavailable(error.localizedDescription)
            }
            isApplying = false
        }
    }

    func selectLanguage(_ mapping: LanguageMapping) {
        let coordinator = coordinator
        Task {
            do {
                try await Task.detached {
                    try coordinator.selectLanguage(mapping.languageCode)
                }.value
                state = .ready
            } catch {
                state = .unavailable(error.localizedDescription)
            }
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemService.setEnabled(enabled)
            launchAtLogin = LoginItemService.isEnabled
        } catch {
            launchAtLogin = LoginItemService.isEnabled
            state = .unavailable(error.localizedDescription)
        }
    }
}
