# ListenCare

ListenCare helps deaf and hard-of-hearing people follow nearby conversations through readable **English and Urdu live captions**. It is a Flutter app with no account requirement, a lightweight device speech engine, and locally saved conversation notes.

The 2.0 redesign follows the supplied reference: white rounded surfaces, lavender cards, fine borders, purple/pink/apricot accents, and an animated listening ring. Phones have Conversations, Listen, and Search tabs; wide screens show all three panels. Content is adapted to accessible conversations rather than the reference's productivity tasks.

## Features

- Live partial captions without repeated text; pause/resume preserves the conversation.
- A dedicated Settings page for English/Urdu, **Device service / Offline only**, and caption size.
- Selectable captions, Urdu RTL layout, bundled Inter/Noto Naskh Arabic fonts, accessible control labels, and reduced-motion support.
- Save, search, filter, view, copy, and delete conversations on this device.
- Real weekly/daily/monthly activity and recent searches; no fabricated statistics or AI features.
- A new vector ListenCare logo and generated launcher icons for Android, iOS, web, macOS, and Windows.

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

The OS can end listening after silence or a session limit. Captions are preserved and the microphone can be tapped to continue; this is not an always-on recognizer. Audio is not recorded or saved by ListenCare. Saved text uses device-local app storage, not a server or backup service.

## Architecture and specification workflow

```text
lib/
  app.dart, main.dart           composition and dependency injection
  screens/                     responsive shell and settings
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

Start behavioral changes in [the specifications](docs/specs/), update acceptance tests alongside the implementation, and run the CI checks. [ADR 001](docs/decisions/001-architecture-and-speech.md) records the engine/architecture decision and future downloadable multilingual engine tradeoffs. [The audit](docs/verification.md) distinguishes automated verification from device acceptance still required.

The old unused model archives remain in the repository but are **not included in the application bundle**. The model under `vosk-model-ur` is Indian English, not Urdu. Legacy generated files under `assets/images/build/` are also excluded from the bundle and ignored for future additions.

## Original 2024 screenshots

![Original splash](https://github.com/user-attachments/assets/1d5095d7-9657-42fc-a21e-605ad2961533)
![Original application](https://github.com/user-attachments/assets/4bed543e-ad7b-4828-ab54-e4aba2891c0e)
