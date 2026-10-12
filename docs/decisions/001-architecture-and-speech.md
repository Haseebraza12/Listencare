# ADR 001 — Feature boundaries and lightweight speech

Accepted: 2026-10-12

## Context
The 2024 UI owned a speech recognizer and appended cumulative interim results. A second unused static service closed a broadcast stream permanently on stop. Settings were placeholders. Unused 76 MB model archives included Indian English mislabeled as Urdu. The README contained screenshots, not requirements.

## Decision
Use a small feature-based architecture with Flutter's built-in ChangeNotifier/ListenableBuilder, constructor injection, a pure transcript buffer, an application controller, platform speech adapter, and local-store interface. No extra state-management package or heavyweight architecture framework is needed for this app.

Dependency direction: presentation → application → domain. Data adapters implement injected interfaces. A single app-owned recognizer handles speech. Versioned specs define observable requirements; regression tests verify the important failure cases. Changes to behavior update the spec and tests in the same change.

Upgrade speech_to_text from 6.6 to 7.5, using SpeechListenOptions and explicit locales. Use platform speech services for a small installation and fast startup. Do not bundle the unused Vosk models. Preserve those source archives in the repository for now; they are not app assets.

Offline only is an explicit setting, gated by native on-device support, with no cloud fallback. Urdu recognition and offline availability depend on the OS/provider and installed packs. Browser offline-only cannot be guaranteed and is disabled. Platform recognizers target phrases and bounded sessions rather than always-on captioning.

## Alternatives
A bundled multilingual Whisper/whisper.cpp model can make Urdu offline independent of OS packs, but adds model downloads, native inference integration, memory/battery cost, latency, and device benchmarking. Do not claim that the bundled English Vosk model supports Urdu. A future downloadable multilingual engine can implement SpeechEngine without changing presentation or transcript logic.

## Sources
- https://pub.dev/packages/speech_to_text (API, supported platforms, session limitations)
- https://github.com/csdcorp/speech_to_text (native on-device handling)
- https://alphacephei.com/vosk/models (model language identities)
