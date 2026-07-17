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
2. `AquaSettingsFile` synchronizes Aqua's managed activation hotkeys and forces
   `streamingMode` to `always`. It creates
   `settings.aquarium-backup.json` before the first write.
3. `AquaCoordinator` launches `/Applications/Aqua Voice.app` with
   `--automation-socket ~/Library/Application Support/Aquarium/aqua.sock`.
4. `ShortcutMonitor` observes `flagsChanged` events through a listen-only HID
   event tap. It does not suppress or synthesize keyboard events.
5. On key-down, `AquaAutomationClient` writes the mapping's language code to
   Aqua before Aqua handles its configured activation hotkey.

Aqua remains responsible for hold-to-stream, release-to-finish, double-tap
hands-free mode, audio capture, transcription, and text insertion.

## Permissions

Aquarium needs Input Monitoring because it observes global modifier-key events.
The socket lives inside a per-user `0700` directory and is validated as a
user-owned Unix socket before Aquarium connects. It does not need
Accessibility, Microphone, Screen Recording, or App Sandbox
exceptions.

## Aqua settings

Aquarium only owns activation entries for `MetaRight`, `AltRight`, and
`ControlRight`. Other Aqua hotkeys remain untouched. Configuration changes are
written while Aqua is stopped, then Aqua is relaunched with its automation
socket.

The Aqua automation protocol is undocumented. Keep protocol use isolated in
`AquaAutomationClient` and treat connection failures as a compatibility issue,
not as permission failures.

## Distribution

`script/package_app.sh` creates the real app bundle and a generated `.icns`.
Local builds use a stable ad-hoc designated requirement so macOS permission
identity survives rebuilds. Public releases should use a Developer ID
Application certificate, hardened runtime, and Apple notarization.
