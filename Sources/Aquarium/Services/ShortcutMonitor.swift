import CoreGraphics
import Foundation

enum ShortcutMonitorError: LocalizedError {
    case permissionRequired
    case eventTapUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            "Allow Aquarium in Privacy & Security → Input Monitoring."
        case .eventTapUnavailable:
            "Aquarium could not start its keyboard event monitor."
        }
    }
}

final class ShortcutMonitor {
    private let client: AquaAutomationClient
    private let lock = NSLock()
    private var mappingsByKeyCode: [Int64: LanguageMapping] = [:]
    private var pressTracker = ModifierPressTracker()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(client: AquaAutomationClient) {
        self.client = client
    }

    func update(mappings: [LanguageMapping]) {
        lock.lock()
        mappingsByKeyCode = Dictionary(
            uniqueKeysWithValues: mappings.map { ($0.hotkey.keyCode, $0) }
        )
        lock.unlock()
    }

    func start() throws {
        guard eventTap == nil else { return }
        guard CGPreflightListenEventAccess() || CGRequestListenEventAccess() else {
            throw ShortcutMonitorError.permissionRequired
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
    }

    private func handle(event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        lock.lock()
        let mapping = mappingsByKeyCode[keyCode]
        lock.unlock()
        guard let mapping else { return }

        let isPressed = CGEventSource.keyState(
            .combinedSessionState,
            key: CGKeyCode(keyCode)
        )
        if pressTracker.shouldActivate(
            keyCode: keyCode,
            isPhysicallyPressed: isPressed
        ) {
            try? client.setLanguage(mapping.languageCode)
        }
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
            if let tap = monitor.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .flagsChanged else {
            return Unmanaged.passUnretained(event)
        }
        _ = proxy
        monitor.handle(event: event)
        return Unmanaged.passUnretained(event)
    }
}

struct ModifierPressTracker {
    private var pressedKeys = Set<Int64>()

    mutating func shouldActivate(
        keyCode: Int64,
        isPhysicallyPressed: Bool
    ) -> Bool {
        if isPhysicallyPressed {
            return pressedKeys.insert(keyCode).inserted
        }
        pressedKeys.remove(keyCode)
        return false
    }
}
