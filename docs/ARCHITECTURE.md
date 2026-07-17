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
2. `SettingsStore` persists one shared Aqua activation shortcut entered by the
   user. Aquarium never reads or writes Aqua's settings.
3. `AquaCoordinator` launches `/Applications/Aqua Voice.app` with
   `--automation-socket ~/Library/Application Support/Aquarium/aqua.sock` and
   leaves Aqua a quiet startup window before the first health check.
4. `ShortcutMonitor` observes modifier changes plus normal key-down and key-up
   events through a listen-only HID event tap.
5. The event callback records the transition on a serial relay queue and
   returns immediately, avoiding a deadlock with Aqua's own keyboard-event
   processing.
6. On key-down, `AquaAutomationClient` writes the mapping's language code and
   waits for Aqua's response on that relay queue.
7. Only after that response, Aquarium posts the shared user-configured Aqua
   activation event. Key-up is queued behind it and forwarded to the same
   shortcut.

Aqua remains responsible for hold-to-stream, release-to-finish, double-tap
hands-free mode, audio capture, transcription, and text insertion.

## Permissions

Aquarium needs Input Monitoring because it observes global modifier-key events,
and Accessibility because it posts the hidden relay events.
The socket lives inside a per-user `0700` directory and is validated as a
user-owned Unix socket before Aquarium connects. It does not need
Microphone, Screen Recording, or App Sandbox exceptions.

## Aqua settings

The user owns Aqua's hotkey and streaming-mode configuration. Aquarium does not
read or write Aqua's settings and does not send settings mutations through
automation. The Aqua hotkey is entered manually. Language triggers can be
modifier-only keys or arbitrary keyboard chords. The shared Aqua relay hotkey
must not match a language trigger.

The Aqua automation protocol is undocumented and is used only to select the
language. Keep protocol use isolated in `AquaAutomationClient` and treat
connection failures as a compatibility issue, not as permission failures.

## Distribution

`script/package_app.sh` creates the real app bundle and a generated `.icns`.
Local builds use a stable ad-hoc designated requirement so macOS permission
identity survives rebuilds. Public releases should use a Developer ID
Application certificate, hardened runtime, and Apple notarization.
