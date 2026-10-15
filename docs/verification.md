# Modernization audit and verification

## Single-screen simplification — October 14, 2026

Version 2.1 removes bottom navigation and the old multi-panel screens. The main notepad has font/size/animation settings, top-bar saved notes/search, and a compact listening-only microphone pulse. Saving keeps the editor open. Settings pause dictation and preserve the draft before opening.

STT improvements include shared stop/cancellation futures, final-result settlement after silence, recognition-error cleanup before offering retry, late-callback isolation, and Android detection of either default or on-device recognition services. Real-plugin method-channel tests exercise startup confirmation, interim/final results, offline/locale routing, and recovery after errors; they do not substitute for successful recognition on real hardware.

Validation: static analysis reports no issues; all 53 tests pass; the Android x64 debug APK builds. Version 2.1.0 (build 3) was installed over the existing emulator app after backing up its shared preferences. Device smoke checks confirmed the no-tabs editor, settings sheet, missing-provider error/help path, typing, draft persistence, and draft restoration after an app restart. Temporary test text was removed; existing saved notes were retained.

The original API 34 AOSP emulator has no registered `RecognitionService`, which correctly exercises the unavailable-provider path. An official Android 36 Google Play image was then installed for the existing Pixel 6 AVD. It exposes Google TTS and Android System Intelligence recognition services. On that device, the microphone permission prompt completed, ListenCare opened an `en-US` recognition session, Android opened the microphone, pause invoked native `onStopListening`, and the app returned to the editable idle notepad. Two on-device listening frames differed by 5,490 pixels in the microphone region, confirming that the pulse animation runs only during a confirmed session. The headless emulator could not initialize host PulseAudio, so spoken-word accuracy is still a physical-device or visible-emulator acceptance check.

## Notepad restoration — October 12, 2026

The previous redesign removed the original editable notepad. The primary screen now restores multiline typing with optional dictation, pause-to-edit, save/copy/new-note actions, saved-note updates under the same identity, and local draft recovery. Notes and search operate on real stored data; decorative activity charts and the large listening ring have been removed from the active UI.

Additional coverage exercises manual text plus cumulative recognition, corrected text plus resumed dictation, preserved blank lines and Urdu, draft restart recovery, older v2 library compatibility, serialized autosaves, storage failure/retry, saved-note editing without duplication, keyboard/large-text layouts, recognizer startup confirmation, missing Android speech services, and permission-dialog/background transitions.

Emulator inspection returned no configured `voice_recognition_service` and no service responding to `android.speech.RecognitionService`. Therefore successful microphone dictation cannot be certified on this emulator. The native app now checks availability, reports missing providers, and opens Android speech settings. Install/enable a provider on a suitable Google Play image or verify on a configured physical phone. This app change does not install an OS speech service.

Validation completed: `flutter analyze` reports no issues; all 44 tests pass; `flutter build apk --debug --target-platform android-x64` succeeds. Rendered previews were reviewed at phone size, with responsive tests at 320, 390, 768, and 1504 widths. The build reports existing upcoming Gradle/AGP/Kotlin support deprecation warnings; these did not block compilation.

The existing v2 persistence key/schema is retained; draft fields are optional when reading older documents. The existing library is preserved. Speech errors preserve typed/dictated text and do not disable the notepad.

## Issues addressed

| Issue | Root cause / change | Verification |
| --- | --- | --- |
| Words appear multiple times | Cumulative speech hypotheses were appended. Replace a session's hypothesis and retain completed sessions separately. | Buffer, controller, and mic-flow widget tests |
| A second recording cannot reuse the old service | Unused global stream was closed permanently on stop. Removed duplicate service; inject one app-owned adapter. | Start/stop/resume controller tests |
| Placeholder text becomes editable transcript | Placeholder was stored as caption text. Render an empty-state hint separately. | Widget flow |
| Rapid taps and late results | No operation guards, generation isolation, or disposal. Added state machine, session generations, cancellation, final-result settlement. | Controller regression tests |
| Language and settings controls did nothing | Placeholder callbacks and default recognition locale. Added persisted settings and explicit language routing. | Persistence/controller/widget tests |
| Incorrect Urdu model and oversized app assets | Indian English zip labeled Urdu; both unused model archives bundled. Remove asset declarations and use the lightweight OS engine. | Pubspec and release asset inspection |
| Missing platform permissions/visibility | iOS/macOS speech privacy strings and Android recognition-service query absent. Added declarations and macOS audio entitlement. | Source review; physical OS permission test pending |
| Offline mode could use default recognizer | Package falls back when Android local recognizer is absent. Added native availability gate; browser mode disabled. | Android adapter gate test; airplane-mode device test pending |
| Save failures could lose data | Added versioned single-document store; clear draft only after successful save; refuse writes after unreadable storage. | Store/controller regression tests |
| UI, icon paths, splash navigation | Orange legacy screen, local absolute icon path, delayed navigation without mounted guard. Replaced UI, relative icon generation, immediate accessible startup. | Responsive widget tests and generated previews |
| Old Android toolchain | AGP 7.3 / Kotlin 1.7 / Java 8. Updated AGP 8.11.1, Kotlin 2.2.20, Java 17. | Android build attempt; see remaining checks |

## Automated checks

The suite covers transcript accumulation/corrections/repeats in English and Urdu, rapid start, clear while initializing, stale results, final words on pause, permission/error recovery, explicit locale routing, offline preference/gating, save/reload/failure/double-save, settings protection, corrupt storage, recent searches, actual preference serialization, microphone UI, settings interactions, search/detail navigation, Urdu text direction, and layout at 320×568, 390×844, 768×1024, 1504×1128.

CI runs formatting, analysis, tests, and a release web build. Optional preview capture loads the actual bundled fonts and icon font and writes local review images; production contains no fixture conversations.

## Required device acceptance

- Real Android and iOS microphone permission flows, including denial and re-enabling permissions.
- English and Urdu recognition accuracy with nearby speech, noise, accents, and installed/missing language packs.
- Offline-only airplane-mode behavior. Urdu offline is not guaranteed by this implementation; it depends on the device's local recognizer.
- Background/interruption behavior, final words on pause, headset behavior, platform session limits, screen readers, and large OS text.
- iOS/macOS builds require macOS/Xcode and were not run on this Linux host.
- Pixel equality with the supplied raster reference has not been certified. Panel dimensions, spacing, palette, typography, and ribbon design were implemented from it; app-specific content and OS chrome differ intentionally.
- Configure production signing and a release application identity before distributing to stores. Existing debug signing and application ID were retained.

The repository still tracks legacy build artifacts under `assets/images/build/`. They are not bundled; removing the historic generated files can be handled as repository housekeeping.
