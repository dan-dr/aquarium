import AppKit
import Darwin
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
    private let monitor: ShortcutMonitor

    init(client: AquaAutomationClient = .init()) {
        self.client = client
        monitor = ShortcutMonitor(client: client)
    }

    func apply(
        mappings: [LanguageMapping],
        forceRestart: Bool = false
    ) throws {
        monitor.update(mappings: mappings)

        if forceRestart || !isConnected {
            try restartAqua()
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

    private func restartAqua() throws {
        guard FileManager.default.fileExists(
            atPath: Self.aquaApplicationURL.path
        ) else {
            throw AquaCoordinatorError.aquaNotInstalled
        }

        terminateRunningAqua()
        try client.removeStaleSocket()

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

        Thread.sleep(forTimeInterval: 5)
        let connectionDeadline = Date().addingTimeInterval(5)
        repeat {
            do {
                try client.ping()
                return
            } catch {
                if Date() < connectionDeadline {
                    Thread.sleep(forTimeInterval: 1)
                }
            }
        } while Date() < connectionDeadline
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
        let remaining = applications.filter { !$0.isTerminated }
        remaining.forEach { $0.forceTerminate() }

        let forceDeadline = Date().addingTimeInterval(1)
        while Date() < forceDeadline,
              remaining.contains(where: { !$0.isTerminated })
        {
            Thread.sleep(forTimeInterval: 0.1)
        }
        let killed = remaining.filter { !$0.isTerminated }
        killed.forEach {
            Darwin.kill($0.processIdentifier, SIGKILL)
        }
        let killDeadline = Date().addingTimeInterval(1)
        while Date() < killDeadline,
              killed.contains(where: { !$0.isTerminated })
        {
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
}
