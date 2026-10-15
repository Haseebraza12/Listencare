import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/app.dart';
import 'package:listencare/features/captions/application/caption_controller.dart';
import 'package:listencare/features/captions/domain/speech_engine.dart';
import 'fakes.dart';

void main() {
  late MemoryStore store;
  late FakeSpeechEngine engine;
  late CaptionController c;
  setUp(() {
    store = MemoryStore();
    engine = FakeSpeechEngine();
    c = CaptionController(engine: engine, store: store);
  });
  tearDown(() => c.dispose());

  test(
    'NOTE-01 typing, dictation, corrections, and resume preserve one note',
    () async {
      c.updateDraft('Shopping list\n');
      await c.start();
      engine.emit('milk');
      engine.emit('milk and bred');
      engine.emit('milk and bread', finalResult: true);
      await c.stop();
      expect(c.transcript, 'Shopping list\nmilk and bread');
      c.updateDraft('Shopping list\nmilk, bread, eggs');
      await c.start();
      engine.emit('and tea');
      await c.stop();
      expect(c.transcript, 'Shopping list\nmilk, bread, eggs and tea');
      expect(await c.saveConversation(), isTrue);
      expect(
        store.state.conversations.single.text,
        c.conversations.single.text,
      );
      expect(store.state.draftText, isEmpty);
    },
  );

  test(
    'NOTE-02 draft survives restart, including Urdu and blank lines',
    () async {
      await c.updateSettings(language: CaptionLanguage.urdu);
      c.updateDraft('سلام\n\nمیرا نوٹ');
      await c.flushDraft();
      final restored = CaptionController(
        engine: FakeSpeechEngine(),
        store: store,
      );
      await restored.load();
      expect(restored.transcript, 'سلام\n\nمیرا نوٹ');
      expect(restored.language, CaptionLanguage.urdu);
      restored.dispose();
    },
  );

  test('NOTE-03 editing a saved note updates it without duplicates', () async {
    c.updateDraft('Original note');
    await c.saveConversation();
    final note = c.conversations.single;
    await c.openConversation(note);
    c.updateDraft('Corrected note');
    await c.saveConversation();
    expect(c.conversations, hasLength(1));
    expect(c.conversations.single.id, note.id);
    expect(c.conversations.single.createdAt, note.createdAt);
    expect(c.conversations.single.text, 'Corrected note');
  });

  test(
    'NOTE-04 older autosave cannot overwrite newer edits or saved notes',
    () async {
      store.pendingWrite = Completer<void>();
      c.updateDraft('First');
      final oldSave = c.flushDraft();
      c.updateDraft('Second');
      final newSave = c.flushDraft();
      store.pendingWrite!.complete();
      await Future.wait([oldSave, newSave]);
      expect(store.state.draftText, 'Second');
      expect(c.draftSaved, isTrue);
      await c.saveConversation();
      await c.flushDraft();
      expect(store.state.draftText, isEmpty);
      expect(store.state.conversations.single.text, 'Second');
    },
  );

  test(
    'NOTE-05 failed draft write keeps typed text and allows retry',
    () async {
      store.failWrite = true;
      c.updateDraft('Keep this note');
      await c.flushDraft();
      expect(c.transcript, 'Keep this note');
      expect(c.draftSaved, isFalse);
      expect(c.draftSaveFailed, isTrue);
      store.failWrite = false;
      await c.flushDraft();
      expect(store.state.draftText, 'Keep this note');
      expect(c.draftSaveFailed, isFalse);
    },
  );

  test('MIC-01 listening indicator waits for recognizer startup', () async {
    engine.pendingListen = Completer<void>();
    final start = c.start();
    await Future<void>.delayed(Duration.zero);
    expect(c.state, CaptureState.starting);
    expect(c.isListening, isFalse);
    engine.pendingListen!.complete();
    await start;
    expect(c.isListening, isTrue);
    await c.stop();
  });

  test(
    'MIC-02 failed starts preserve note and allow typing and retry',
    () async {
      c.updateDraft('Typed note');
      engine.listenError = 'error_audio_error';
      await c.start();
      expect(c.state, CaptureState.idle);
      expect(c.error, contains('microphone'));
      expect(c.transcript, 'Typed note');
      final staleResult = engine.result!;
      c.updateDraft('Edited after error');
      staleResult(const SpeechUpdate('late result'));
      expect(c.transcript, 'Edited after error');
      engine.listenError = null;
      await c.start();
      engine.emit('new dictation');
      await c.stop();
      expect(c.transcript, 'Edited after error new dictation');
    },
  );

  testWidgets(
    'MIC-04 permission dialog does not cancel startup; background does',
    (tester) async {
      engine.initialization = Completer<bool>();
      await tester.pumpWidget(ListenCareApp(controller: c));
      final start = c.start();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(c.state, CaptureState.starting);
      engine.initialization!.complete(true);
      await start;
      expect(c.isListening, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(c.isListening, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('NOTE-06 type, save, reopen, edit, and save in the UI', (
    tester,
  ) async {
    await tester.pumpWidget(ListenCareApp(controller: c));
    final editor = find.byKey(const ValueKey('note-editor'));
    await tester.enterText(editor, 'My typed note');
    await tester.pump();
    expect(c.transcript, 'My typed note');
    await tester.tap(find.byTooltip('Note actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();
    expect(c.conversations, hasLength(1));
    expect(c.hasDraft, isTrue);
    expect(c.draftMatchesSaved, isTrue);
    await tester.tap(find.byTooltip('Saved notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My typed note'));
    await tester.pumpAndSettle();
    await tester.enterText(editor, 'My corrected note');
    await tester.pump();
    await tester.tap(find.byTooltip('Note actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(store.state.conversations, hasLength(1));
    expect(store.state.conversations.single.text, 'My corrected note');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('NOTE-07 narrow keyboard layout and large text remain editable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ListenCareApp(controller: c));
    await tester.enterText(
      find.byKey(const ValueKey('note-editor')),
      'A note with the keyboard open',
    );
    await tester.pump();
    expect(c.transcript, 'A note with the keyboard open');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('NOTE-08 clear icon protects and clears an unsaved note', (
    tester,
  ) async {
    await tester.pumpWidget(ListenCareApp(controller: c));
    expect(find.byTooltip('Clear notepad'), findsOneWidget);
    final clear = tester.widget<IconButton>(
      find.byKey(const ValueKey('clear-notepad')),
    );
    expect(clear.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('note-editor')),
      'Draft to clear',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Clear notepad'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new note?'), findsOneWidget);
    await tester.tap(find.text('Discard draft'));
    await tester.pumpAndSettle();

    expect(c.transcript, isEmpty);
    expect(find.text('Draft to clear'), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('clear-notepad')))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
