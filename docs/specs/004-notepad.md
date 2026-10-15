# 004 — Editable notepad and reliable dictation

The original app's editable notepad is core functionality. Captions and styling must not replace it.

- NOTE-01: Open on Notepad. Type multiline text without granting microphone access. Dictation appends to typed or corrected text, replacing interim results only within its own session. Pause to edit without late callbacks overwriting corrections.
- NOTE-02: Autosave drafts after a short debounce and when the app leaves the foreground. Restore text, language, editing identity, and dictation duration. Preserve existing v2 notes; absent draft fields in older documents default to empty.
- NOTE-03: Open a saved note and edit it. Save changes under the same ID and original date, without duplicating the note. Confirm/save an unrelated draft before opening a different note for editing.
- NOTE-04: Serialize local writes so an older autosave cannot overwrite a newer draft or saved library. Main-screen save keeps the current note open and persists its saved identity; save-before-new/open clears a draft only after successful persistence.
- NOTE-05: Failed storage keeps the draft in memory and allows retry; unreadable existing storage is never overwritten.
- NOTE-06: Saved-notes search, copy, save, edit, new-note, and confirmed delete actions operate on real local data. There is no bottom navigation; secondary actions live in the top bar. Remove activity filler and the large decorative listening surface.
- NOTE-07: Preserve usability at narrow widths, with the keyboard open, large text, and Urdu RTL. Navigation dismisses the keyboard and stale snackbars.
- MIC-01: Show connecting until the recognizer confirms startup; never show a running listening timer for failed startup.
- MIC-02: Missing service, permission denial, audio errors, network problems, unsupported languages, busy recognizers, and no speech return to editable idle state with the note preserved. Errors must offer a useful reason, retry, and Android speech-settings access.
- MIC-03: Check Android speech-service availability before capture. A microphone permission grant cannot supply a missing service. Do not silently change language or bypass offline-only requirements.

Verification: notepad, controller, adapter, storage, and responsive widget tests; Android debug compilation. Real English/Urdu microphone accuracy and offline behavior require a device with a configured speech provider. The inspected AOSP emulator has no registered RecognitionService, so it cannot validate successful dictation.
