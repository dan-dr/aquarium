---
read_when:
  - Debugging Aqua Voice automation or native bridge integration
  - Evaluating replacement of Aquarium's synthetic hotkey relay
---

# Aqua Voice protocols

This is a reverse-engineered compatibility note, not a supported Aqua Voice
API contract. Results below were captured against Aqua Voice 0.16.9 on
2026-07-18.

## Process and socket topology

Aquarium launches Aqua Voice with:

```text
--automation-socket ~/Library/Application Support/Aquarium/aqua.sock
```

That creates two different local Unix sockets:

| Socket | Owner | Purpose |
| --- | --- | --- |
| `~/Library/Application Support/Aquarium/aqua.sock` | Aqua Voice Electron main process | External automation requests used by Aquarium |
| `~/Library/Application Support/Aqua Voice/bridge.sock` | `AquaMacOSBridge` helper | Private connection between Aqua's Electron main process and native macOS helper |

These are separate protocols. Aquarium currently uses only the automation
socket.

## Automation socket

The automation socket accepts one newline-delimited JSON request per
connection and returns a newline-delimited JSON response:

```json
{"id":"unique-id","command":"ping"}
```

```json
{"id":"unique-id","ok":true,"result":{"pong":true,"ts":"..."}}
```

Aquarium changes the language with:

```json
{
  "id": "unique-id",
  "command": "settings.set",
  "params": {"key": "language", "value": "he"}
}
```

### Aqua Voice 0.16.9 command surface

Inspection of the bundled `AutomationCommandRouter` found these commands:

- `ping`
- `app.info`
- `updates.status`
- `updates.checkNow`
- `updates.installDownloaded`
- `runtime.ensureOwner`
- `dictation.start`
- `computerControl.executeAction`
- `settings.keys`
- `settings.get`
- `settings.getMany`
- `settings.set`
- `settings.setMany`
- `settings.reset`
- `ui.openSettings`
- `microphones.listNative`
- `microphones.selectNative`
- `history.list`
- `history.latest`
- `runtime.snapshot`

Only the commands Aquarium needs should be used. This surface is undocumented
and may change in any Aqua release.

### Dictation lifecycle experiment

Live requests produced these results:

| Request | Result |
| --- | --- |
| `dictation.start` | Succeeded, entered `priming` with `pttState: active`, and started native microphone capture |
| `dictation.stop` | `unknown_command` |
| `dictation.lock` | `unknown_command` |
| `dictation.cancel` | `unknown_command` |

The internal Aqua dictation orchestrator implements `start`, `lock`, `stop`,
and `cancel`, but the automation router exposes only `dictation.start`.
Supplying a different lifecycle type in request parameters does not reach that
internal dispatcher because the router calls its fixed `startDictation()`
service method.

This means the automation socket cannot currently replace Aquarium's relay:
hold-to-stream needs a release command, and hands-free mode needs the lock
transition. Starting through automation without a supported stop path can
leave recording active.

`dictation.start` and `runtime.snapshot` can return a full runtime snapshot.
It may include authentication data, settings, and transcription history. Do
not log or persist raw automation responses.

## Native bridge socket

The native helper uses JSON envelopes framed by `<||EOM||>` rather than
newlines:

```text
{"type":"push_to_talk_start_request"}<||EOM||>
```

Binary inspection found direct handlers for:

- `push_to_talk_start_request`
- `push_to_talk_stop_request`
- `push_to_talk_lock_request`
- `push_to_talk_cancel_request`

The same bridge also handles native audio, microphone selection, accessibility,
focused-app context, screenshots, paste and key actions, offline models, and
state synchronization. It is an internal transport, not a narrow dictation
API.

### Second-client experiment

Connecting a second Unix-socket client while Aqua Voice was running did not
replace or disturb Aqua's connection. The helper immediately closed the new
connection and logged:

```text
ipc.connection_rejected_existing_client
```

The existing Aqua Electron connection remained open and the automation socket
continued responding. Therefore Aquarium cannot send those PTT requests by
opening another bridge connection.

A bridge proxy or a patch inside Aqua could theoretically multiplex the one
allowed connection. Either would sit inside a broad private protocol, create a
large compatibility and security surface, and risk breaking audio or runtime
state synchronization on Aqua updates. Aquarium does not do this.

## Current integration decision

Keep the supported behavior split:

1. Use the automation socket only for `settings.set` language selection.
2. Relay the user-configured Aqua hotkey for press, release, and double-tap
   semantics.
3. Keep Aqua responsible for dictation lifecycle, audio, transcription, and
   paste.

Revisit direct lifecycle control if Aqua exposes `dictation.stop`,
`dictation.lock`, and `dictation.cancel` on the automation socket or publishes
a supported client API.

## Test recovery

The live `dictation.start` probe was canceled by quitting Aqua after macOS
blocked a synthetic Escape from the test runner. Aqua was relaunched with the
same `--automation-socket` argument, and `runtime.snapshot` then reported
`phase: idle` and `pttState: inactive`.
