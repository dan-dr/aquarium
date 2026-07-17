# Changelog

## 0.2.0

- Relay physical modifiers to hidden Aqua Voice shortcuts after the language
  change is confirmed, eliminating the activation race.
- Preserve hold-to-stream and double-tap hands-free behavior through synthetic
  key-down and key-up events.
- Mirror Aqua Voice's English and native language labels and exact language
  codes, including Mandarin (`cmn`) and Yiddish (`yi`).
- Remove per-language icons.
- Read Aqua activation hotkeys without modifying Aqua settings, with manual
  shortcut entry as a fallback.
- Add focused hotkey relay telemetry and regression tests.

## 0.1.0

- Native macOS menu-bar app and settings window.
- Up to three per-hotkey language mappings.
- Per-language icons.
- Aqua Voice streaming and hands-free behavior preserved.
- Launch-at-login support.
- App bundling, signing, release, and Homebrew tap scaffolding.
