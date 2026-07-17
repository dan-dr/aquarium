import AppKit
import SwiftUI

struct HotkeyRecorder: View {
    @Binding var hotkey: HotkeyOption

    @State private var eventMonitor: Any?
    @State private var pendingModifier: HotkeyOption?

    private var isRecording: Bool {
        eventMonitor != nil
    }

    var body: some View {
        Button(action: toggleRecording) {
            HStack {
                Text(isRecording ? "Press a shortcut…" : hotkey.displayName)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: isRecording ? "record.circle" : "keyboard")
                    .foregroundStyle(isRecording ? .red : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Choose hotkey")
        .onDisappear(perform: stopRecording)
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        pendingModifier = nil
        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .flagsChanged]
        ) { event in
            DispatchQueue.main.async {
                handle(event)
            }
            return nil
        }
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            guard let modifier = HotkeyOption.modifierOnly(
                keyCode: Int64(event.keyCode)
            ) else {
                return
            }
            let flags = HotkeyOption.eventFlags(from: event.modifierFlags)
            if modifier.isPressed(in: flags) {
                pendingModifier = modifier
            } else if pendingModifier?.keyCode == Int64(event.keyCode) {
                hotkey = modifier
                stopRecording()
            }

        case .keyDown:
            guard !event.isARepeat else { return }
            let modifiers = HotkeyOption.eventFlags(from: event.modifierFlags)
            if event.keyCode == 53, modifiers.isEmpty {
                stopRecording()
                return
            }
            hotkey = .keyboard(
                keyCode: Int64(event.keyCode),
                modifiers: modifiers,
                keyLabel: HotkeyOption.keyLabel(for: event)
            )
            stopRecording()

        default:
            break
        }
    }

    private func stopRecording() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
        pendingModifier = nil
    }
}
