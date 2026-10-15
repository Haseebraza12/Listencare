# 003 — Simple notepad interface

Status: implemented in 2.1, superseding the earlier dashboard layout.

- One main editor at every screen width; no bottom tabs or three-panel dashboard.
- Top bar: brand, Notepad title, Saved notes, Settings, and note-actions menu.
- Editor: full-height multiline typing, Urdu RTL, persisted font/size, and a recoverable error banner that opens full details without consuming the writing area.
- Bottom: one microphone with connecting/cancel, listening/pause, finishing, and idle states, plus selected language/mode. A small pulse animates only during confirmed listening. Respect the animation setting and OS reduced motion.
- Saved notes: real local records, search, language filters, direct editing, and confirmed deletion.
- Settings: compact sheet over the main screen with font, text size, animation, language, speech mode, preview, and Android speech-settings access.
- White and lavender surfaces, Inter/Noto Naskh Arabic fonts, purple/pink/apricot accents. No fake status bars, statistics, audio meters, or recording animations while idle.
- Narrow/short layouts and open keyboards can scroll. Large text and OS safe areas remain supported.

Verification: single-screen, settings, animation, notepad, and responsive widget tests; review captured phone previews and the installed emulator app.
