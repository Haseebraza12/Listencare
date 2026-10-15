import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:listencare/features/captions/data/device_speech_engine.dart';
import 'package:listencare/features/captions/domain/speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const plugin = MethodChannel('plugin.csdcorp.com/speech_to_text');
  const capabilities = MethodChannel('listencare/speech_capabilities');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late DeviceSpeechEngine engine;
  late List<String> errors;
  late Completer<void> listenRequested;
  Completer<void>? cancelGate;
  Map<dynamic, dynamic>? listenOptions;

  Future<void> callback(String method, Object args) async {
    final completed = Completer<void>();
    messenger.handlePlatformMessage(
      plugin.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) => completed.complete(),
    );
    await completed.future;
  }

  Future<void> words(String text, {bool finalResult = false}) => callback(
    'textRecognition',
    jsonEncode({
      'alternates': [
        {'recognizedWords': text, 'confidence': .9},
      ],
      'resultType': finalResult ? 2 : 0,
    }),
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    engine = DeviceSpeechEngine(speech: SpeechToText.withMethodChannel());
    errors = [];
    listenRequested = Completer<void>();
    cancelGate = null;
    listenOptions = null;
    messenger.setMockMethodCallHandler(capabilities, (_) async => true);
    messenger.setMockMethodCallHandler(plugin, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'locales':
          return ['en_US:English', 'ur_PK:Urdu'];
        case 'listen':
          listenOptions = call.arguments as Map<dynamic, dynamic>;
          if (!listenRequested.isCompleted) listenRequested.complete();
          return true;
        case 'cancel':
          if (cancelGate != null) await cancelGate!.future;
          return true;
        case 'stop':
          await words('hello world', finalResult: true);
          await callback('notifyStatus', 'done');
          return true;
      }
      return null;
    });
  });
  tearDown(() async {
    cancelGate?.complete();
    cancelGate = null;
    await engine.cancel();
    messenger.setMockMethodCallHandler(plugin, null);
    messenger.setMockMethodCallHandler(capabilities, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'STT-01 real plugin bridge confirms startup, replaces hypotheses, and returns final on stop',
    () async {
      final updates = <SpeechUpdate>[];
      expect(
        await engine.initialize(onStatus: (_) {}, onError: errors.add),
        isTrue,
      );
      var started = false;
      final start = engine
          .listen(locale: 'ur-PK', offline: true, onResult: updates.add)
          .then((_) => started = true);
      await listenRequested.future;
      expect(started, isFalse);
      await callback('notifyStatus', 'listening');
      await start;
      expect(listenOptions!['localeId'], 'ur-PK');
      expect(listenOptions!['onDevice'], isTrue);
      await words('hello');
      await engine.stop();
      expect(updates.map((u) => u.words), ['hello', 'hello world']);
      expect(updates.last.isFinal, isTrue);
      expect(errors, isEmpty);
    },
  );

  test(
    'STT-02 error cleanup completes before retry; a new session remains active',
    () async {
      await engine.initialize(onStatus: (_) {}, onError: errors.add);
      final start = engine.listen(
        locale: 'en-US',
        offline: false,
        onResult: (_) {},
      );
      await listenRequested.future;
      await callback('notifyStatus', 'listening');
      await start;
      cancelGate = Completer<void>();
      await callback(
        'notifyError',
        jsonEncode({'errorMsg': 'error_audio_error', 'permanent': true}),
      );
      expect(errors, isEmpty);
      cancelGate!.complete();
      cancelGate = null;
      await Future<void>.delayed(Duration.zero);
      expect(errors, ['error_audio_error']);
      listenRequested = Completer<void>();
      final retry = engine.listen(
        locale: 'en-US',
        offline: false,
        onResult: (_) {},
      );
      await listenRequested.future;
      await callback('notifyStatus', 'listening');
      await retry;
      await engine.stop();
      expect(errors, hasLength(1));
    },
  );
}
