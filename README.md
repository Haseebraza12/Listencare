# ListenCare

ListenCare is an English and Urdu **editable notepad with optional microphone dictation**. Type a note, dictate into it, pause to correct words, and save it locally. The notepad opens first and remains usable when speech recognition is unavailable.

Version 2.1 uses one notepad screen with white and lavender surfaces. The top bar opens Settings, Saved notes, and the note-actions menu. There is no bottom navigation or multi-panel dashboard. A compact microphone at the bottom pulses during confirmed listening; idle and unavailable states stay still.

## Features

- Editable multiline notes with copy, save, reopen, update, and confirmed deletion. Saving keeps the current note open; repeated saves update the same note. Save/copy/new-note actions live in the top menu.
- Debounced local draft recovery, including typed text, dictated text, language, and elapsed dictation time. Saving an existing note updates it without creating duplicates.
- Dictation replaces interim hypotheses without repeating words. Pause to edit; resume appends a new speech session after your corrected note.
- Actual recognizer startup confirmation, recoverable error messages, retry, and Android speech-settings access. Failed recognition preserves the note and restores editing.
- Settings on the main screen control font family, text size, microphone animation, English/Urdu, and device-service/offline-only mode. Urdu uses RTL. Motion respects the OS reduced-motion preference.
- Saved notes include local search and language filters. No account, sample records, or fabricated activity.

## Run and verify

Validated with Flutter 3.47.7 / Dart 3.13.5; the resolved dependencies require Flutter 3.44+ / Dart 3.12+. Use JDK 17 for Android. Android requires API 24+; enforced offline recognition requires Android 12/API 31+ with an available on-device recognizer and the selected language pack. iOS/macOS require their normal Flutter/Xcode toolchains.

```sh
flutter pub get
flutter run
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug --target-platform android-arm64
```

For browser speech, use HTTPS or localhost and a supported browser. Linux can display the UI but does not provide the speech engine. Windows speech support is supplied by the upstream package and requires device verification.

Render review previews at 320, 390, 768, and 1504 logical-pixel widths:

```sh
flutter test --dart-define=CAPTURE_PREVIEWS=true
```

Previews are written to `artifacts/previews/` (ignored by Git). To regenerate the brand PNG and native icons:

```sh
flutter test tool/generate_brand.dart
dart run flutter_launcher_icons
```

The icon generator currently changes `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` in the iOS project incorrectly; retain `YES` for that boolean Xcode setting after regeneration.

## Speech modes

**Device service** uses `speech_to_text` 7.5 and the OS/browser recognizer. It avoids downloading bundled inference models. The provider may process audio online, and Urdu availability varies by device.

**Offline only** requests local recognition and refuses to start if the platform cannot enforce it. Android has an additional native capability check to prevent the package's default-recognizer fallback. Apple platforms use the package's required-on-device recognition. Browser offline mode is disabled. A setting does not install an Urdu model: an unsupported/missing language pack produces an explanation instead of silently switching to English or online processing.

The OS can end listening after silence or a session limit. Your note is preserved and the microphone can be tapped to continue; this is not an always-on recognizer. Audio is not recorded or saved by ListenCare. Drafts and saved text use device-local app storage, not a server or backup service.

## Android microphone setup

Dictation needs an installed and enabled Android `RecognitionService`. A plain AOSP emulator can have microphone permission but no speech provider. The app now checks for this before capture and explains the problem rather than showing a running timer.

Use a Google Play emulator image with an enabled speech provider, or a physical phone with speech recognition configured. Check microphone permission for both ListenCare and the provider (for example, the Google app), allow host microphone input in emulator Extended Controls, and verify recognition in the provider itself. Device-service mode may also need internet. These requirements come from the [speech plugin's Android troubleshooting guide](https://github.com/csdcorp/speech_to_text/blob/main/speech_to_text/README.md#not-working-on-an-android-emulator).

After native Android changes, stop the current Flutter run and launch again; hot reload does not replace the platform channel code.

## Architecture and specification workflow

```text
lib/
  app.dart, main.dart           composition and dependency injection
  screens/                     single notepad shell, notes library, settings sheet
  features/
    captions/
      domain/                  speech contract and pure transcript buffer
      application/             capture lifecycle and application actions
      data/                    platform speech adapter
      presentation/            live-caption panel
    library/
      domain/                  conversation, local-store contract, saved state
      data/                    versioned preferences adapter
      presentation/            activity, search, conversation tiles
  theme/, widgets/             visual tokens and reusable vector/UI components
```

Presentation talks to `CaptionController`; speech/storage implementations are injected through interfaces. There is one recognizer, no speech plugin inside screen state, and no permanently closed static stream.

Behavior is recorded in [the specifications](docs/specs/), including the restored notepad requirements. Update acceptance tests alongside behavioral changes and run the CI checks. [ADR 001](docs/decisions/001-architecture-and-speech.md) records the engine/architecture decision and future downloadable multilingual engine tradeoffs. [The audit](docs/verification.md) distinguishes automated verification from device acceptance still required.

The old unused model archives remain in the repository but are **not included in the application bundle**. The model under `vosk-model-ur` is Indian English, not Urdu. Legacy generated files under `assets/images/build/` are also excluded from the bundle and ignored for future additions.

## Original 2024 screenshots

![Original splash](https://github.com/user-attachments/assets/1d5095d7-9657-42fc-a21e-605ad2961533)
![Original application](https://github.com/user-attachments/assets/4bed543e-ad7b-4828-ab54-e4aba2891c0e)
