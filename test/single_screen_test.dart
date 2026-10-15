import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/app.dart';
import 'package:listencare/features/captions/application/caption_controller.dart';
import 'package:listencare/features/captions/domain/note_preferences.dart';
import 'package:listencare/widgets/microphone_control.dart';
import 'fakes.dart';

void main() {
  testWidgets(
    'SIMPLE-01 editor fills the single screen without bottom navigation',
    (tester) async {
      final c = CaptionController(
        engine: FakeSpeechEngine(),
        store: MemoryStore(),
      );
      await tester.pumpWidget(ListenCareApp(controller: c));
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byTooltip('Saved notes'), findsOneWidget);
      final editor = find.byKey(const ValueKey('note-editor'));
      await tester.enterText(editor, 'A simple notepad');
      await tester.pump();
      expect(c.transcript, 'A simple notepad');
      expect(tester.getSize(editor).height, greaterThan(300));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'SET-03 font and animation settings persist and affect the editor',
    (tester) async {
      final store = MemoryStore();
      final c = CaptionController(engine: FakeSpeechEngine(), store: store);
      await tester.pumpWidget(ListenCareApp(controller: c));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('note-font-setting')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Noto Naskh Arabic').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Microphone animation'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(store.state.noteFont, NoteFont.naskh);
      expect(store.state.animationsEnabled, isFalse);
      await tester.tap(find.byTooltip('Close settings'));
      await tester.pumpAndSettle();
      final editor = tester.widget<TextField>(
        find.byKey(const ValueKey('note-editor')),
      );
      expect(editor.style!.fontFamily, 'NotoNaskhArabic');
      final restored = CaptionController(
        engine: FakeSpeechEngine(),
        store: store,
      );
      await restored.load();
      expect(restored.noteFont, NoteFont.naskh);
      expect(restored.animationsEnabled, isFalse);
      restored.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'ANIM-01 pulse moves while listening and stops when paused or reduced',
    (tester) async {
      Widget control({
        required bool listening,
        bool enabled = true,
        bool reduced = false,
      }) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: MicrophoneControl(
            listening: listening,
            connecting: false,
            animationsEnabled: enabled,
            onPressed: () {},
          ),
        ),
      );
      double scale() => tester
          .widget<Transform>(find.byKey(const ValueKey('microphone-pulse')))
          .transform
          .storage[0];
      await tester.pumpWidget(control(listening: true));
      final first = scale();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(), isNot(first));
      await tester.pumpWidget(control(listening: false));
      final paused = scale();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(), paused);
      await tester.pumpWidget(control(listening: true, reduced: true));
      final reduced = scale();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(), reduced);
      await tester.pumpWidget(control(listening: true, enabled: false));
      final disabled = scale();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(), disabled);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('MIC-05 silence without done settles and preserves final words', (
    tester,
  ) async {
    final engine = FakeSpeechEngine();
    final c = CaptionController(engine: engine, store: MemoryStore());
    await tester.pumpWidget(ListenCareApp(controller: c));
    await c.start();
    engine.emit('hello');
    engine.status!('notListening');
    await tester.pump(const Duration(seconds: 1));
    engine.emit('hello world', finalResult: true);
    await tester.pump(const Duration(seconds: 3));
    expect(c.isListening, isFalse);
    expect(c.transcript, 'hello world');
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'MIC-06 concurrent stop calls share cancellation and prevent new starts',
    () async {
      final engine = FakeSpeechEngine();
      final c = CaptionController(engine: engine, store: MemoryStore());
      engine.stopping = Completer<void>();
      await c.start();
      final first = c.stop();
      final second = c.stop();
      await c.start();
      expect(engine.starts, 1);
      engine.stopping!.complete();
      await Future.wait([first, second]);
      expect(c.isBusy, isFalse);
      c.dispose();
    },
  );

  test(
    'SIMPLE-02 saving keeps current note open and updates the same saved copy',
    () async {
      final store = MemoryStore();
      final c = CaptionController(engine: FakeSpeechEngine(), store: store);
      c.updateDraft('Keep visible');
      await c.saveConversation(keepOpen: true);
      final id = c.editingId;
      expect(c.transcript, 'Keep visible');
      expect(store.state.draftId, id);
      c.updateDraft('Keep corrected');
      await c.saveConversation(keepOpen: true);
      expect(c.conversations, hasLength(1));
      expect(c.editingId, id);
      expect(c.conversations.single.text, 'Keep corrected');
      c.dispose();
    },
  );
}
