import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/features/captions/data/device_speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'CAP-08 Android without local recognizer refuses offline before listening',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('listencare/speech_capabilities');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => false);
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      await expectLater(
        DeviceSpeechEngine().listen(
          locale: 'ur-PK',
          offline: true,
          onResult: (_) {},
        ),
        throwsUnsupportedError,
      );
    },
  );
}
