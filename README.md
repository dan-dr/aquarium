# Aquarium

Per-hotkey language routing for [Aqua Voice](https://aquavoice.com/) on macOS.

Aquarium is a native menu-bar companion. Assign up to three languages to Aqua
Voice activation keys, then keep Aqua's normal interaction model:

- Hold a key for streaming dictation in its assigned language.
- Release to finish.
- Double-tap the same key for Aqua Voice hands-free mode.

Example mappings:

| Trigger | Language |
| --- | --- |
| Right Command | English |
| Right Option | Hebrew |

Triggers are recorded directly. They can be a modifier-only key, such as
Right Command, a pure modifier chord such as Shift + Command + Control +
Option, or any normal key combination.

## Requirements

- macOS 14 or newer
- Aqua Voice installed at `/Applications/Aqua Voice.app`
- Input Monitoring and Accessibility permissions for Aquarium

Aquarium currently integrates with Aqua Voice's local, undocumented automation
socket. An Aqua Voice update may change that interface.

## Setup

1. In Aqua Voice, enable streaming mode.
2. Set one Aqua Voice activation hotkey. A complex shortcut such as
   `Meta+Alt+Control+Shift+F17` avoids conflicts.
3. Open Aquarium Settings and record the same shortcut in **Aqua hotkey**.
4. For each language, choose a language and record any trigger you want.
5. Click **Apply**.

Aquarium never reads or changes Aqua's settings.

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

1. Stores up to three language and arbitrary-hotkey mappings.
2. Stores the Aqua Voice activation hotkey you record manually.
3. Launches Aqua Voice with its local automation socket enabled.
4. On trigger press, switches Aqua's language and waits for confirmation. A
   same-language second tap skips the repeated switch so it reaches Aqua inside
   the native hands-free timing window.
5. Posts the shared Aqua hotkey press and release to macOS's global keyboard
   stream so Aqua's global shortcut listener receives it, keeping
   hold-to-stream and double-tap hands-free behavior intact.

Aquarium does not capture audio, transcribe speech, or replace Aqua Voice.
Injected relay events carry an Aquarium marker, so Aquarium ignores its own
events instead of relaying them again. A pure modifier chord is recommended for
the shared Aqua hotkey because it cannot type into the focused app.

See [Architecture](docs/ARCHITECTURE.md) for implementation and security
details.

## License

MIT
