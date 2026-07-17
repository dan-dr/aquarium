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
        event.flags = shortcut.flags
        event.post(tap: .cghidEventTap)
    }
}

final class HotkeyRelay {
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
    private var mappingsByKeyCode: [Int64: LanguageMapping] = [:]
    private var pressTracker = ModifierPressTracker()

    init(
        languageSelector: any AquaLanguageSelecting,
        hotkeyPoster: any AquaHotkeyPosting
    ) {
        self.languageSelector = languageSelector
        self.hotkeyPoster = hotkeyPoster
    }

    func update(mappings: [LanguageMapping]) {
        lock.lock()
        let pressedKeyCodes = pressTracker.reset()
        let releases = pressedKeyCodes.compactMap { keyCode in
            mappingsByKeyCode[keyCode]?.aquaShortcut
        }
        mappingsByKeyCode = Dictionary(
            uniqueKeysWithValues: mappings.map { ($0.hotkey.keyCode, $0) }
        )
        lock.unlock()

        relayQueue.async { [weak self] in
            guard let self else { return }
            releases.forEach { self.relayRelease($0) }
        }
    }

    func handle(keyCode: Int64, flags: CGEventFlags) {
        lock.lock()
        guard let mapping = mappingsByKeyCode[keyCode] else {
            lock.unlock()
            return
        }
        let transition = pressTracker.transition(
            keyCode: keyCode,
            modifierIsPresent: mapping.hotkey.isPressed(in: flags)
        )
        lock.unlock()

        switch transition {
        case .pressed:
            relayQueue.async { [weak self] in
                self?.relayPress(mapping)
            }
        case .released:
            relayQueue.async { [weak self] in
                self?.relayRelease(mapping.aquaShortcut)
            }
        case .ignored:
            break
        }
    }

    func resetPressedKeys() {
        lock.lock()
        let keyCodes = pressTracker.reset()
        let shortcuts = keyCodes.compactMap {
            mappingsByKeyCode[$0]?.aquaShortcut
        }
        lock.unlock()

        relayQueue.async { [weak self] in
            guard let self else { return }
            shortcuts.forEach { self.relayRelease($0) }
        }
    }

    func waitUntilIdle() {
        relayQueue.sync {}
    }

    private func relayPress(_ mapping: LanguageMapping) {
        do {
            try languageSelector.setLanguage(mapping.languageCode)
            try hotkeyPoster.post(
                shortcut: mapping.aquaShortcut,
                keyDown: true
            )
            logger.info(
                "Relayed \(mapping.hotkey.rawValue, privacy: .public) as \(mapping.aquaShortcut, privacy: .public) after selecting \(mapping.languageCode, privacy: .public)"
            )
        } catch {
            logger.error(
                "Relay failed for \(mapping.hotkey.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func relayRelease(_ shortcut: String) {
        do {
            try hotkeyPoster.post(shortcut: shortcut, keyDown: false)
            logger.debug(
                "Released relay \(shortcut, privacy: .public)"
            )
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

    func update(mappings: [LanguageMapping]) {
        relay.update(mappings: mappings)
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
        logger.info("Global modifier monitor started")
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

        guard type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }
        _ = proxy
        monitor.relay.handle(
            keyCode: event.getIntegerValueField(.keyboardEventKeycode),
            flags: event.flags
        )
        return Unmanaged.passUnretained(event)
    }
}

enum ModifierTransition: Equatable {
    case pressed
    case released
    case ignored
}

struct ModifierPressTracker {
    private var pressedKeys = Set<Int64>()

    mutating func transition(
        keyCode: Int64,
        modifierIsPresent: Bool
    ) -> ModifierTransition {
        if pressedKeys.remove(keyCode) != nil {
            return .released
        }
        guard modifierIsPresent else { return .ignored }
        pressedKeys.insert(keyCode)
        return .pressed
    }

    mutating func reset() -> Set<Int64> {
        defer { pressedKeys.removeAll() }
        return pressedKeys
    }
}
