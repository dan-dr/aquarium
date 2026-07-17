import AppKit
import Foundation

enum AquaCoordinatorError: LocalizedError {
    case aquaNotInstalled
    case launchFailed
    case connectionTimedOut

    var errorDescription: String? {
        switch self {
        case .aquaNotInstalled:
            "Aqua Voice is not installed in /Applications."
        case .launchFailed:
            "Aquarium could not launch Aqua Voice."
        case .connectionTimedOut:
            "Aqua Voice did not open its automation connection in time."
        }
    }
}

final class AquaCoordinator {
    static let aquaBundleIdentifier = "com.electron.aqua-voice"
    static let aquaApplicationURL = URL(
        fileURLWithPath: "/Applications/Aqua Voice.app"
    )

    private let client: AquaAutomationClient
    private let settingsFile: AquaSettingsFile
    private let monitor: ShortcutMonitor

    init(
        client: AquaAutomationClient = .init(),
        settingsFile: AquaSettingsFile = .init()
    ) {
        self.client = client
        self.settingsFile = settingsFile
        monitor = ShortcutMonitor(client: client)
    }

    func apply(
        mappings: [LanguageMapping],
        forceRestart: Bool = false
    ) throws {
        monitor.update(mappings: mappings)

        if forceRestart || !settingsFile.matches(mappings) || !isConnected {
            try restartAqua(with: mappings)
        }

        try client.ping()
        try monitor.start()
    }

    func selectLanguage(_ languageCode: String) throws {
        try client.setLanguage(languageCode)
    }

    private var isConnected: Bool {
        do {
            try client.ping()
            return true
        } catch {
            return false
        }
    }

    private func restartAqua(with mappings: [LanguageMapping]) throws {
        guard FileManager.default.fileExists(
            atPath: Self.aquaApplicationURL.path
        ) else {
            throw AquaCoordinatorError.aquaNotInstalled
        }

        terminateRunningAqua()
        try client.removeStaleSocket()
        try settingsFile.apply(mappings)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [
            "-a", "Aqua Voice", "--args",
            "--automation-socket", client.socketPath,
        ]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AquaCoordinatorError.launchFailed
        }

        for _ in 0 ..< 80 {
            if isConnected { return }
            Thread.sleep(forTimeInterval: 0.125)
        }
        throw AquaCoordinatorError.connectionTimedOut
    }

    private func terminateRunningAqua() {
        let applications = NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.aquaBundleIdentifier
        )
        applications.forEach { $0.terminate() }

        let deadline = Date().addingTimeInterval(4)
        while Date() < deadline, applications.contains(where: { !$0.isTerminated }) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        applications.filter { !$0.isTerminated }.forEach { $0.forceTerminate() }
    }
}
