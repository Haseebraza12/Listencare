# 002 — Conversations and settings

Status: implemented; local persistence integration covered by tests.

- LIB-01: Save only a nonempty paused draft. Store text, language, timestamp, and listening duration locally. Clear the draft only after a successful write.
- LIB-02: Show actual saved-conversation counts and duration for the current week/day/month. Never fabricate activity, AI summaries, or sample conversations in production.
- LIB-03: Search saved text, combine with an English/Urdu filter, open full selectable captions, copy text, and delete with confirmation.
- LIB-04: Remember the last six distinct submitted searches. Remove individual search chips.
- SET-01: A dedicated Settings page persists language, device/offline recognition mode, and caption size across restarts.
- SET-02: Do not change language during capture or while an unsaved draft belongs to another language. Explain how to save/clear first.
- DATA-01: Version the persisted document. Preserve the draft on write failure and existing storage on unreadable data. Never silently overwrite corrupt storage with an empty library.
- DATA-02: Do not record/store audio or add an external backend. Explain platform-service processing, device-local storage, and removal on uninstall/clearing browser data.

Storage is suitable for a small personal library. A database with pagination and explicit migrations should replace preferences when library scale warrants it. App storage is not application-level encrypted or a backup service.
