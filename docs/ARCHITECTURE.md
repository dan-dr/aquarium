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
2. `SettingsStore` persists one shared Aqua activation shortcut recorded by the
   user. Aquarium never reads or writes Aqua's settings.
3. `AquaCoordinator` launches `/Applications/Aqua Voice.app` with
   `--automation-socket ~/Library/Application Support/Aquarium/aqua.sock` and
   leaves Aqua a quiet startup window before the first health check.
4. `ShortcutMonitor` observes modifier changes plus normal key-down and key-up
   events through an active HID event tap. Configured language triggers are
   consumed so Aqua and the focused app do not see the original trigger.
5. The event callback records the transition on a serial relay queue and
   returns immediately, avoiding a deadlock with Aqua's own keyboard-event
   processing.
6. On key-down, `AquaAutomationClient` writes the mapping's language code and
   waits for Aqua's response on that relay queue. A repeated press for the same
   language within one second reuses that selection so Aqua receives both taps
   inside its native 0.4-second hands-free window.
7. Aquarium posts the shared user-configured Aqua activation event to macOS's
   global HID stream because Aqua listens for its shortcut globally. A language
   socket failure is logged but does not suppress the activation event. Pure
   modifier chords are emitted as individual physical modifier transitions,
   matching Aqua's native bridge state machine. Key-up is queued behind
   key-down and posted to the same stream.
8. Injected events carry an Aquarium-specific user-data marker. The event tap
   ignores that marker, preventing Aquarium from relaying its own events.

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
automation. The Aqua hotkey is recorded manually. Hotkeys can be a single
modifier, a pure multi-modifier chord, or an arbitrary keyboard chord. The
shared Aqua relay hotkey must not match a language trigger.

The Aqua automation protocol is undocumented and is used only to select the
language. Keep protocol use isolated in `AquaAutomationClient` and treat
connection failures as a compatibility issue, not as permission failures.
See [Aqua Voice protocols](AQUA-PROTOCOLS.md) for the tested automation and
native bridge boundaries.

## Distribution

`script/package_app.sh` creates the real app bundle and a generated `.icns`.
Local builds use a stable ad-hoc designated requirement so macOS permission
identity survives rebuilds. Public releases should use a Developer ID
Application certificate, hardened runtime, and Apple notarization.
