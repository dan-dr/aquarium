import CoreGraphics
import Foundation
import OSLog

enum ShortcutMonitorError: LocalizedError {
    case inputMonitoringPermissionRequired
    case accessibilityPermissionRequired
    case eventTapUnavailable

    var errorDescription: String? {
        switch self {
        case .inputMonitoringPermissionRequired:
            "Allow Aquarium in Privacy & Security → Input Monitoring."
        case .accessibilityPermissionRequired:
            "Allow Aquarium in Privacy & Security → Accessibility."
        case .eventTapUnavailable:
            "Aquarium could not start its keyboard event monitor."
        }
    }
}

protocol AquaLanguageSelecting {
    func setLanguage(_ languageCode: String) throws
}

extension AquaAutomationClient: AquaLanguageSelecting {}

protocol AquaHotkeyPosting {
    func post(shortcut: String, keyDown: Bool) throws
}

enum AquaHotkeyPosterError: LocalizedError {
    case invalidShortcut
    case eventCreationFailed

    var errorDescription: String? {
        switch self {
        case .invalidShortcut:
            "The Aqua Voice relay hotkey is not supported."
        case .eventCreationFailed:
            "Aquarium could not create Aqua Voice's relay hotkey event."
        }
    }
}

struct SystemAquaHotkeyPoster: AquaHotkeyPosting {
    private let source = CGEventSource(stateID: .privateState)

    func post(shortcut value: String, keyDown: Bool) throws {
        guard let shortcut = AquaShortcut(value) else {
            throw AquaHotkeyPosterError.invalidShortcut
        }
        guard let event = CGEvent(
            keyboardEventSource: source,
            virtualKey: shortcut.keyCode,
            keyDown: keyDown
        ) else {
            throw AquaHotkeyPosterError.eventCreationFailed
        }
        event.flags = shortcut.isModifierOnly && !keyDown ? [] : shortcut.flags
        event.post(tap: .cghidEventTap)
    }
}

final class HotkeyRelay {
    private struct ActiveRelay {
        let mapping: LanguageMapping
        let aquaShortcut: String
    }

    private let languageSelector: any AquaLanguageSelecting
    private let hotkeyPoster: any AquaHotkeyPosting
    private let lock = NSLock()
    private let logger = Logger(
        subsystem: "com.danrosenshain.Aquarium",
        category: "HotkeyRelay"
    )
    private let relayQueue = DispatchQueue(
        label: "com.danrosenshain.Aquarium.hotkey-relay",
        qos: .userInteractive
    )
    private var mappings: [LanguageMapping] = []
    private var aquaShortcut = ""
    private var activeRelays: [UUID: ActiveRelay] = [:]

    init(
        languageSelector: any AquaLanguageSelecting,
        hotkeyPoster: any AquaHotkeyPosting
    ) {
        self.languageSelector = languageSelector
        self.hotkeyPoster = hotkeyPoster
    }

    func update(mappings: [LanguageMapping], aquaShortcut: String) {
        lock.lock()
        let releases = Array(activeRelays.values)
        activeRelays.removeAll()
        self.mappings = mappings
        self.aquaShortcut = aquaShortcut
        lock.unlock()

        relayQueue.async { [weak self] in
            guard let self else { return }
            releases.forEach { self.relayRelease($0.aquaShortcut) }
        }
    }

    func handle(
        type: CGEventType,
        keyCode: Int64,
        flags: CGEventFlags,
        isRepeat: Bool = false
    ) {
        lock.lock()
        let transition = transition(
            type: type,
            keyCode: keyCode,
            flags: flags,
            isRepeat: isRepeat
        )
        lock.unlock()

        switch transition {
        case let .pressed(active):
            relayQueue.async { [weak self] in
                self?.relayPress(active)
            }
        case let .released(active):
            relayQueue.async { [weak self] in
                self?.relayRelease(active.aquaShortcut)
            }
        case .ignored:
            break
        }
    }

    func resetPressedKeys() {
        lock.lock()
        let releases = Array(activeRelays.values)
        activeRelays.removeAll()
        lock.unlock()

        relayQueue.async { [weak self] in
            guard let self else { return }
            releases.forEach { self.relayRelease($0.aquaShortcut) }
        }
    }

    func waitUntilIdle() {
        relayQueue.sync {}
    }

    private enum RelayTransition {
        case pressed(ActiveRelay)
        case released(ActiveRelay)
        case ignored
    }

    private func transition(
        type: CGEventType,
        keyCode: Int64,
        flags: CGEventFlags,
        isRepeat: Bool
    ) -> RelayTransition {
        switch type {
        case .flagsChanged:
            if let active = activeRelays.values.first(where: {
                $0.mapping.hotkey.isModifierOnly
                    && $0.mapping.hotkey.keyCode == keyCode
            }) {
                activeRelays.removeValue(forKey: active.mapping.id)
                return .released(active)
            }

            guard let mapping = mappings.first(where: {
                $0.hotkey.isModifierOnly
                    && $0.hotkey.keyCode == keyCode
                    && $0.hotkey.isPressed(in: flags)
            }) else {
                return .ignored
            }
            let active = ActiveRelay(
                mapping: mapping,
                aquaShortcut: aquaShortcut
            )
            activeRelays[mapping.id] = active
            return .pressed(active)

        case .keyDown:
            guard !isRepeat else { return .ignored }
            guard let mapping = mappings.first(where: {
                !$0.hotkey.isModifierOnly
                    && $0.hotkey.matches(keyCode: keyCode, flags: flags)
                    && activeRelays[$0.id] == nil
            }) else {
                return .ignored
            }
            let active = ActiveRelay(
                mapping: mapping,
                aquaShortcut: aquaShortcut
            )
            activeRelays[mapping.id] = active
            return .pressed(active)

        case .keyUp:
            guard let active = activeRelays.values.first(where: {
                !$0.mapping.hotkey.isModifierOnly
                    && $0.mapping.hotkey.keyCode == keyCode
            }) else {
                return .ignored
            }
            activeRelays.removeValue(forKey: active.mapping.id)
            return .released(active)

        default:
            return .ignored
        }
    }

    private func relayPress(_ active: ActiveRelay) {
        do {
            try languageSelector.setLanguage(active.mapping.languageCode)
            try hotkeyPoster.post(
                shortcut: active.aquaShortcut,
                keyDown: true
            )
            logger.info(
                "Relayed \(active.mapping.hotkey.displayName, privacy: .public) as \(active.aquaShortcut, privacy: .public) after selecting \(active.mapping.languageCode, privacy: .public)"
            )
        } catch {
            logger.error(
                "Relay failed for \(active.mapping.hotkey.displayName, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func relayRelease(_ shortcut: String) {
        do {
            try hotkeyPoster.post(shortcut: shortcut, keyDown: false)
            logger.debug("Released relay \(shortcut, privacy: .public)")
        } catch {
            logger.error(
                "Relay release failed for \(shortcut, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}

final class ShortcutMonitor {
    private let relay: HotkeyRelay
    private let logger = Logger(
        subsystem: "com.danrosenshain.Aquarium",
        category: "HotkeyMonitor"
    )
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(
        client: AquaAutomationClient,
        hotkeyPoster: any AquaHotkeyPosting = SystemAquaHotkeyPoster()
    ) {
        relay = HotkeyRelay(
            languageSelector: client,
            hotkeyPoster: hotkeyPoster
        )
    }

    func update(mappings: [LanguageMapping], aquaShortcut: String) {
        relay.update(mappings: mappings, aquaShortcut: aquaShortcut)
    }

    func start() throws {
        guard eventTap == nil else { return }
        let canListen = CGPreflightListenEventAccess()
            || CGRequestListenEventAccess()
        logger.info("Input Monitoring allowed: \(canListen, privacy: .public)")
        guard canListen else {
            throw ShortcutMonitorError.inputMonitoringPermissionRequired
        }
        let canPost = CGPreflightPostEventAccess()
            || CGRequestPostEventAccess()
        logger.info("Accessibility allowed: \(canPost, privacy: .public)")
        guard canPost else {
            throw ShortcutMonitorError.accessibilityPermissionRequired
        }

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
            | CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.keyUp.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: Self.eventCallback,
            userInfo: userInfo
        ) else {
            throw ShortcutMonitorError.eventTapUnavailable
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        logger.info("Global hotkey monitor started")
    }

    private static let eventCallback: CGEventTapCallBack = {
        proxy, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let monitor = Unmanaged<ShortcutMonitor>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            monitor.relay.resetPressedKeys()
            if let tap = monitor.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .flagsChanged || type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }
        _ = proxy
        monitor.relay.handle(
            type: type,
            keyCode: event.getIntegerValueField(.keyboardEventKeycode),
            flags: event.flags,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        )
        return Unmanaged.passUnretained(event)
    }
}
