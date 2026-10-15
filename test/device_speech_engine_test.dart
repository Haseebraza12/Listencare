import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/features/captions/data/device_speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'MIC-03 missing Android speech provider is reported before capture',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('listencare/speech_capabilities');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'isRecognitionAvailable');
            return false;
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      String? error;
      final available = await DeviceSpeechEngine().initialize(
        onStatus: (_) {},
        onError: (value) => error = value,
      );
      expect(available, isFalse);
      expect(error, 'speech_service_unavailable');
    },
  );
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
