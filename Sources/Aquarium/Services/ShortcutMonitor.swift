import CoreGraphics
import Foundation
import OSLog

enum AquariumInjectedEvent {
    static let marker: Int64 = 0x415155415249554D

    static func mark(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: marker)
    }

    static func matches(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == marker
    }
}

struct AquaHotkeyEventStep: Equatable {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
    let keyDown: Bool
    let type: CGEventType
}

enum AquaHotkeyEventSequence {
    private struct ModifierKey {
        let flag: CGEventFlags
        let leftKeyCode: CGKeyCode
        let rightKeyCode: CGKeyCode?

        func keyCode(preferred: Int64) -> CGKeyCode {
            let preferredKeyCode = CGKeyCode(preferred)
            if preferredKeyCode == leftKeyCode
                || preferredKeyCode == rightKeyCode
            {
                return preferredKeyCode
            }
            return leftKeyCode
        }
    }

    private static let modifierKeys = [
        ModifierKey(
            flag: .maskCommand,
            leftKeyCode: 55,
            rightKeyCode: 54
        ),
        ModifierKey(
            flag: .maskAlternate,
            leftKeyCode: 58,
            rightKeyCode: 61
        ),
        ModifierKey(
            flag: .maskControl,
            leftKeyCode: 59,
            rightKeyCode: 62
        ),
        ModifierKey(
            flag: .maskShift,
            leftKeyCode: 56,
            rightKeyCode: 60
        ),
        ModifierKey(
            flag: .maskSecondaryFn,
            leftKeyCode: 63,
            rightKeyCode: nil
        ),
    ]

    static func steps(
        for hotkey: HotkeyOption,
        keyDown: Bool
    ) -> [AquaHotkeyEventStep] {
        guard hotkey.isModifierOnly else {
            return [
                AquaHotkeyEventStep(
                    keyCode: CGKeyCode(hotkey.keyCode),
                    flags: keyDown ? hotkey.modifiers : [],
                    keyDown: keyDown,
                    type: keyDown ? .keyDown : .keyUp
                ),
            ]
        }

        let keys = modifierKeys.filter {
            hotkey.modifiers.contains($0.flag)
        }
        if keyDown {
            var pressedFlags: CGEventFlags = []
            return keys.map { key in
                pressedFlags.insert(key.flag)
                return AquaHotkeyEventStep(
                    keyCode: key.keyCode(preferred: hotkey.keyCode),
                    flags: pressedFlags,
                    keyDown: true,
                    type: .flagsChanged
                )
            }
        }

        var pressedFlags = hotkey.modifiers
        return keys.reversed().map { key in
            pressedFlags.remove(key.flag)
            return AquaHotkeyEventStep(
                keyCode: key.keyCode(preferred: hotkey.keyCode),
                flags: pressedFlags,
                keyDown: false,
                type: .flagsChanged
            )
        }
    }
}

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
    func post(hotkey: HotkeyOption, keyDown: Bool) throws
}

enum AquaHotkeyPosterError: LocalizedError {
    case eventCreationFailed

    var errorDescription: String? {
        switch self {
        case .eventCreationFailed:
            "Aquarium could not create Aqua Voice's relay hotkey event."
        }
    }
}

struct SystemAquaHotkeyPoster: AquaHotkeyPosting {
    private let source = CGEventSource(stateID: .privateState)

    func post(hotkey: HotkeyOption, keyDown: Bool) throws {
        for step in AquaHotkeyEventSequence.steps(
            for: hotkey,
            keyDown: keyDown
        ) {
            guard let event = CGEvent(
                keyboardEventSource: source,
                virtualKey: step.keyCode,
                keyDown: step.keyDown
            ) else {
                throw AquaHotkeyPosterError.eventCreationFailed
            }
            event.flags = step.flags
            event.type = step.type
            AquariumInjectedEvent.mark(event)
            event.post(tap: .cghidEventTap)
        }
    }
}

final class HotkeyRelay {
    private static let languageSelectionFreshness: TimeInterval = 1

    private struct ActiveRelay {
        let mapping: LanguageMapping
        let aquaHotkey: HotkeyOption
    }

    private let languageSelector: any AquaLanguageSelecting
    private let hotkeyPoster: any AquaHotkeyPosting
    private let now: () -> Date
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
    private var aquaHotkey = HotkeyOption.suggestedAquaRelay
    private var activeRelays: [UUID: ActiveRelay] = [:]
    private var lastLanguageAttempt: (code: String, date: Date)?

    init(
        languageSelector: any AquaLanguageSelecting,
        hotkeyPoster: any AquaHotkeyPosting,
        now: @escaping () -> Date = Date.init
    ) {
        self.languageSelector = languageSelector
        self.hotkeyPoster = hotkeyPoster
        self.now = now
    }

    func update(mappings: [LanguageMapping], aquaHotkey: HotkeyOption) {
        lock.lock()
        let releases = Array(activeRelays.values)
        activeRelays.removeAll()
        self.mappings = mappings
        self.aquaHotkey = aquaHotkey
        lock.unlock()

        relayQueue.async { [weak self] in
            guard let self else { return }
            releases.forEach { self.relayRelease($0.aquaHotkey) }
        }
    }

    @discardableResult
    func handle(
        type: CGEventType,
        keyCode: Int64,
        flags: CGEventFlags,
        isRepeat: Bool = false
    ) -> Bool {
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
                self?.relayRelease(active.aquaHotkey)
            }
        case .ignored:
            return false
        }
        return true
    }

    func resetPressedKeys() {
        lock.lock()
        let releases = Array(activeRelays.values)
        activeRelays.removeAll()
        lock.unlock()

        relayQueue.async { [weak self] in
            guard let self else { return }
            releases.forEach { self.relayRelease($0.aquaHotkey) }
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
                aquaHotkey: aquaHotkey
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
                aquaHotkey: aquaHotkey
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
        let languageCode = active.mapping.languageCode
        let currentDate = now()
        let selectionIsFresh = lastLanguageAttempt.map {
            $0.code == languageCode
                && currentDate.timeIntervalSince($0.date)
                    < Self.languageSelectionFreshness
        } ?? false

        if !selectionIsFresh {
            lastLanguageAttempt = (languageCode, currentDate)
            do {
                try languageSelector.setLanguage(languageCode)
            } catch {
                logger.error(
                    "Language selection failed for \(languageCode, privacy: .public); relaying Aqua hotkey anyway: \(error.localizedDescription, privacy: .public)"
                )
            }
        }

        do {
            try hotkeyPoster.post(
                hotkey: active.aquaHotkey,
                keyDown: true
            )
            logger.info(
                "Relayed \(active.mapping.hotkey.displayName, privacy: .public) as \(active.aquaHotkey.displayName, privacy: .public) for \(languageCode, privacy: .public)"
            )
        } catch {
            logger.error(
                "Relay failed for \(active.mapping.hotkey.displayName, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func relayRelease(_ hotkey: HotkeyOption) {
        do {
            try hotkeyPoster.post(hotkey: hotkey, keyDown: false)
            logger.debug("Released relay \(hotkey.displayName, privacy: .public)")
        } catch {
            logger.error(
                "Relay release failed for \(hotkey.displayName, privacy: .public): \(error.localizedDescription, privacy: .public)"
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

    func update(mappings: [LanguageMapping], aquaHotkey: HotkeyOption) {
        relay.update(mappings: mappings, aquaHotkey: aquaHotkey)
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
            options: .defaultTap,
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
        guard !AquariumInjectedEvent.matches(event) else {
            return Unmanaged.passUnretained(event)
        }
        _ = proxy
        let handled = monitor.relay.handle(
            type: type,
            keyCode: event.getIntegerValueField(.keyboardEventKeycode),
            flags: event.flags,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        )
        return handled ? nil : Unmanaged.passUnretained(event)
    }
}
