# Aquarium

Per-hotkey language routing for [Aqua Voice](https://aquavoice.com/) on macOS.

Aquarium is a native menu-bar companion. Assign up to three languages to Aqua
Voice activation keys, then keep Aqua's normal interaction model:

- Hold a key for streaming dictation in its assigned language.
- Release to finish.
- Double-tap the same key for Aqua Voice hands-free mode.

Default mappings:

| Trigger | Language |
| --- | --- |
| Right Command | English |
| Right Option | Hebrew |

## Requirements

- macOS 14 or newer
- Aqua Voice installed at `/Applications/Aqua Voice.app`
- Input Monitoring permission for Aquarium

Aquarium currently integrates with Aqua Voice's local, undocumented automation
socket. An Aqua Voice update may change that interface.

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

1. Stores up to three language, icon, and modifier-key mappings.
2. Keeps Aqua Voice in streaming mode and synchronizes its activation hotkeys.
3. Launches Aqua Voice with its local automation socket enabled.
4. Observes the configured modifier key and switches Aqua's language before
   Aqua handles the same event.

Aquarium does not capture audio, transcribe speech, or replace Aqua Voice.

See [Architecture](docs/ARCHITECTURE.md) for implementation and security
details.

## License

MIT
