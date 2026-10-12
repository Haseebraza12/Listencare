# 001 — Accessible live captions

Status: implemented; physical-device acceptance pending.

## Purpose
ListenCare makes nearby speech readable for deaf and hard-of-hearing people.
English and Urdu captions are the primary experience. No account is needed.

## Required behavior

- CAP-01: A session emitting `hello`, `hello world`, final `hello world`, and a repeated final displays exactly `hello world`.
- CAP-02: A recognizer correction replaces its hypothesis. Intentional speech such as `very very good` stays intact. Do not deduplicate adjacent words.
- CAP-03: Pause preserves captions; resume starts a new hypothesis after the existing text. Repeated phrases across distinct sessions are intentional and preserved.
- CAP-04: Only one listening/start operation may be active. Final callbacks during stop are accepted. Cleared, saved, superseded, and disposed sessions cannot change the draft.
- CAP-05: Denied permission, missing speech service, unsupported language, network failure, and no speech leave a recoverable idle screen with the draft preserved.
- CAP-06: Recognition must explicitly use the selected language. Prefer en-US / ur-PK, then the same language family; never fall back from Urdu to English.
- CAP-07: Backgrounding stops capture. Disposing releases the microphone and timers. Do not start capture automatically on launch.
- CAP-08: Device service uses the platform recognizer. Offline only requires a verified local recognizer and on-device processing; unsupported environments must fail without online fallback.
- CAP-09: Captions are selectable, size-adjustable (18–36), and RTL in Urdu. Controls have accessible labels and 48+ logical-pixel tap targets. Reduced-motion preferences stop the decorative ring.
- CAP-10: Platform recognizers impose silence/session limits. Display a paused state and preserve text, allowing explicit resume. Do not promise uninterrupted transcription.

## Verification
`test/caption_controller_test.dart`, `test/transcript_buffer_test.dart`, `test/widget_test.dart`.
Physical Android/iOS: test actual English/Urdu speech, airplane-mode offline capture, denied permission, rapid taps, interruptions, final words on pause, headset behavior, and installed/missing language packs.
