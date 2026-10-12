import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/features/captions/application/caption_controller.dart';
import 'package:listencare/features/captions/domain/speech_engine.dart';
import 'fakes.dart';

void main() {
  late FakeSpeechEngine engine;
  late MemoryStore store;
  late CaptionController controller;
  setUp(() {
    engine = FakeSpeechEngine();
    store = MemoryStore();
    controller = CaptionController(engine: engine, store: store);
  });
  tearDown(() => controller.dispose());

  test(
    'CAP-01/03 repeats are fixed through the application flow and resume',
    () async {
      await controller.start();
      engine.emit('hello');
      engine.emit('hello world');
      engine.emit('hello world', finalResult: true);
      expect(controller.transcript, 'hello world');
      await controller.stop();
      await controller.start();
      engine.emit('again');
      expect(controller.transcript, 'hello world again');
      expect(engine.initializations, 1);
    },
  );
  test('CAP-04 rapid start taps initialize and listen once', () async {
    engine.initialization = Completer<bool>();
    final first = controller.start();
    await controller.start();
    expect(engine.initializations, 1);
    engine.initialization!.complete(true);
    await first;
    expect(engine.starts, 1);
  });
  test(
    'CAP-04 clear during permission request ignores pending start',
    () async {
      engine.initialization = Completer<bool>();
      final start = controller.start();
      await controller.clear();
      engine.initialization!.complete(true);
      await start;
      expect(engine.starts, 0);
      expect(controller.state, CaptureState.idle);
    },
  );
  test('CAP-04 clear ignores late results from a discarded session', () async {
    await controller.start();
    engine.emit('old words');
    final oldResult = engine.result!;
    await controller.clear();
    oldResult(const SpeechUpdate('late old words'));
    expect(controller.transcript, isEmpty);
    await controller.start();
    engine.emit('new words');
    oldResult(const SpeechUpdate('late old words'));
    expect(controller.transcript, 'new words');
  });
  test(
    'CAP-04 accepts final words during stop and prevents premature save',
    () async {
      await controller.start();
      engine.emit('hello');
      engine.stopping = Completer<void>();
      engine.finalOnStop = 'hello world';
      final stop = controller.stop();
      engine.status!('notListening');
      expect(controller.state, CaptureState.stopping);
      expect(await controller.saveConversation(), isFalse);
      engine.stopping!.complete();
      await stop;
      expect(controller.transcript, 'hello world');
      expect(controller.state, CaptureState.idle);
    },
  );
  test('CAP-05 denied permission is recoverable without listening', () async {
    engine.available = false;
    await controller.start();
    expect(controller.state, CaptureState.idle);
    expect(controller.error, contains('permission'));
    expect(engine.starts, 0);
  });
  test('CAP-05 errors preserve the current transcript', () async {
    await controller.start();
    engine.emit('keep this');
    engine.error!('error_network');
    expect(controller.state, CaptureState.idle);
    expect(controller.transcript, 'keep this');
    expect(controller.error, isNotNull);
  });
  test('CAP-06/08 Urdu and offline preference reach the engine', () async {
    await controller.updateSettings(
      language: CaptionLanguage.urdu,
      mode: RecognitionMode.offline,
    );
    await controller.start();
    expect(engine.selectedLocale, 'ur_PK');
    expect(engine.selectedOffline, isTrue);
  });
  test(
    'CAP-06 explicitly tries Urdu when the locale list only exposes English',
    () async {
      engine.availableLocales = ['en_US'];
      await controller.updateSettings(language: CaptionLanguage.urdu);
      await controller.start();
      expect(engine.selectedLocale, 'ur-PK');
      engine.error!('error_language_not_supported');
      expect(controller.error, contains('اردو'));
      expect(controller.state, CaptureState.idle);
    },
  );
  test(
    'LIB-01 successful save clears draft and survives controller reload',
    () async {
      await controller.start();
      engine.emit('a saved conversation');
      await controller.stop();
      expect(await controller.saveConversation(), isTrue);
      expect(controller.transcript, isEmpty);
      expect(controller.conversations.single.text, 'a saved conversation');
      final restored = CaptionController(
        engine: FakeSpeechEngine(),
        store: store,
      );
      await restored.load();
      expect(restored.conversations.single.text, 'a saved conversation');
      restored.dispose();
    },
  );
  test('DATA-01 failed save preserves draft and library', () async {
    await controller.start();
    engine.emit('important words');
    await controller.stop();
    store.failWrite = true;
    expect(await controller.saveConversation(), isFalse);
    expect(controller.transcript, 'important words');
    expect(controller.conversations, isEmpty);
  });
  test('LIB-01 double save cannot duplicate a conversation', () async {
    await controller.start();
    engine.emit('one note');
    await controller.stop();
    store.pendingWrite = Completer<void>();
    final first = controller.saveConversation();
    expect(await controller.saveConversation(), isFalse);
    store.pendingWrite!.complete();
    expect(await first, isTrue);
    expect(controller.conversations, hasLength(1));
  });
  test(
    'SET-01/02 settings persist and language cannot relabel an unsaved draft',
    () async {
      await controller.updateSettings(
        language: CaptionLanguage.urdu,
        captionSize: 30,
      );
      await controller.start();
      engine.emit('سلام');
      await controller.stop();
      expect(
        await controller.updateSettings(language: CaptionLanguage.english),
        isFalse,
      );
      expect(controller.language, CaptionLanguage.urdu);
      expect(store.state.captionSize, 30);
    },
  );
  test('DATA-01 unreadable storage is not overwritten by settings', () async {
    store.failRead = true;
    await controller.load();
    expect(
      await controller.updateSettings(mode: RecognitionMode.offline),
      isFalse,
    );
    expect(store.state.mode, RecognitionMode.device);
  });
  test(
    'LIB-04 recent searches deduplicate, cap at six, and can be removed',
    () async {
      for (var i = 0; i < 8; i++) {
        await controller.rememberSearch('query $i');
      }
      await controller.rememberSearch('query 5');
      expect(controller.recentSearches, hasLength(6));
      expect(controller.recentSearches.first, 'query 5');
      await controller.removeSearch('query 5');
      expect(controller.recentSearches, isNot(contains('query 5')));
    },
  );
}
