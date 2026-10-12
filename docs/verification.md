# Modernization audit and verification

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
