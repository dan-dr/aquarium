# Aquarium

Per-hotkey language routing for [Aqua Voice](https://aquavoice.com/) on macOS.

Aquarium is a native menu-bar companion. Assign up to three languages to Aqua
Voice activation keys, then keep Aqua's normal interaction model:

- Hold a key for streaming dictation in its assigned language.
- Release to finish.
- Double-tap the same key for Aqua Voice hands-free mode.

Suggested mappings:

| Trigger | Language | Aqua Voice activation hotkey |
| --- | --- | --- |
| Right Command | English | `MetaRight+F17` |
| Right Option | Hebrew | `AltRight+F18` |

## Requirements

- macOS 14 or newer
- Aqua Voice installed at `/Applications/Aqua Voice.app`
- Input Monitoring and Accessibility permissions for Aquarium

Aquarium currently integrates with Aqua Voice's local, undocumented automation
socket. An Aqua Voice update may change that interface.

## Setup

1. In Aqua Voice, enable streaming mode.
2. Replace Aqua's direct modifier activation hotkeys with complex shortcuts.
   The shortcut must include the trigger modifier and F13 through F20. The
   suggested English shortcut is `MetaRight+F17`; Hebrew is `AltRight+F18`.
3. Open Aquarium Settings and click **Read Aqua Voice Hotkeys**. If detection
   does not match the intended language order, type the Aqua hotkey into each
   mapping manually.
4. Click **Apply**.

Aquarium reads Aqua's activation hotkeys but never changes Aqua's settings.

## Install

### Homebrew

```nu
brew tap dan-dr/tap
brew trust --cask dan-dr/tap/aquarium
brew install --cask aquarium
xattr -dr com.apple.quarantine /Applications/Aquarium.app
```

The initial release is ad-hoc signed, so the quarantine-clear command is
required before first launch. Once release signing and notarization are
configured, that command can be removed.

### Build locally

```nu
git clone https://github.com/dan-dr/aquarium.git
cd aquarium
./script/install.sh
```

## Development

```nu
swift test
./script/build_and_run.sh --verify
```

The build script creates `dist/Aquarium.app`, generates the app icon, applies a
stable local signature, and launches the bundle. The Codex `Run` action uses the
same script.

## How it works

Aquarium:

1. Stores up to three language and modifier-key mappings.
2. Reads Aqua Voice activation hotkeys, or accepts them manually.
3. Launches Aqua Voice with its local automation socket enabled.
4. On modifier press, switches Aqua's language and waits for confirmation.
5. Forwards the configured Aqua hotkey press and release, keeping
   hold-to-stream and double-tap hands-free behavior intact.

Aquarium does not capture audio, transcribe speech, or replace Aqua Voice.

See [Architecture](docs/ARCHITECTURE.md) for implementation and security
details.

## License

MIT
