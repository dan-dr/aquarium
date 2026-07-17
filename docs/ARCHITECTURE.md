---
read_when:
  - Changing Aqua Voice integration or keyboard event routing
  - Modifying signing, permissions, or packaging
---

# Architecture

Aquarium is a SwiftPM-built SwiftUI menu-bar app. It intentionally stays a
companion to Aqua Voice rather than patching Aqua's Electron bundle.

## Data flow

1. `SettingsStore` persists up to three `LanguageMapping` values in
   `UserDefaults`.
2. `AquaSettingsFile` reads Aqua's activation shortcuts for setup convenience.
   It never writes Aqua's settings.
3. `AquaCoordinator` launches `/Applications/Aqua Voice.app` with
   `--automation-socket ~/Library/Application Support/Aquarium/aqua.sock` and
   leaves Aqua a quiet startup window before the first health check.
4. `ShortcutMonitor` observes physical right-modifier `flagsChanged` events
   through a listen-only HID event tap.
5. The event callback records the transition on a serial relay queue and
   returns immediately, avoiding a deadlock with Aqua's own keyboard-event
   processing.
6. On key-down, `AquaAutomationClient` writes the mapping's language code and
   waits for Aqua's response on that relay queue.
7. Only after that response, Aquarium posts the user-configured Aqua function
   key event. Key-up is queued behind it and forwarded to the same shortcut.

Aqua remains responsible for hold-to-stream, release-to-finish, double-tap
hands-free mode, audio capture, transcription, and text insertion.

## Permissions

Aquarium needs Input Monitoring because it observes global modifier-key events,
and Accessibility because it posts the hidden relay events.
The socket lives inside a per-user `0700` directory and is validated as a
user-owned Unix socket before Aquarium connects. It does not need
Microphone, Screen Recording, or App Sandbox exceptions.

## Aqua settings

The user owns Aqua's hotkey and streaming-mode configuration. Aquarium reads
activation shortcuts from `settings.json` when requested, but never writes the
file or sends settings mutations through automation. Manual entry remains
available if Aqua changes its file format. Supported relay shortcuts combine
the physical trigger's modifier with F13 through F20.

The Aqua automation protocol is undocumented and is used only to select the
language. Keep protocol use isolated in `AquaAutomationClient` and treat
connection failures as a compatibility issue, not as permission failures.

## Distribution

`script/package_app.sh` creates the real app bundle and a generated `.icns`.
Local builds use a stable ad-hoc designated requirement so macOS permission
identity survives rebuilds. Public releases should use a Developer ID
Application certificate, hardened runtime, and Apple notarization.
