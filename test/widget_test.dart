import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/app.dart';
import 'package:listencare/features/captions/application/caption_controller.dart';
import 'package:listencare/features/captions/domain/speech_engine.dart';
import 'package:listencare/features/library/domain/conversation.dart';
import 'package:listencare/features/library/domain/local_store.dart';
import 'package:listencare/screens/settings_screen.dart';
import 'fakes.dart';

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('artifacts/previews');
    await directory.create(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    for (final family in ['Inter', 'NotoNaskhArabic']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });
  testWidgets('CAP-01 mobile mic flow renders cumulative results only once', (
    tester,
  ) async {
    final engine = FakeSpeechEngine();
    final controller = CaptionController(engine: engine, store: MemoryStore());
    await tester.pumpWidget(ListenCareApp(controller: controller));
    await tester.tap(find.byTooltip('Start listening'));
    await tester.pump();
    engine.emit('hello');
    engine.emit('hello world');
    engine.emit('hello world', finalResult: true);
    await tester.pump();
    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('hello hello world'), findsNothing);
    await tester.tap(find.byTooltip('Pause listening'));
    await tester.pump();
    expect(controller.state, CaptureState.idle);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1504, 1128),
  ]) {
    testWidgets('UI-01 no layout errors at ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = CaptionController(
        engine: FakeSpeechEngine(),
        store: MemoryStore(),
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('preview'),
          child: ListenCareApp(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, 'home-${size.width.toInt()}');
      if (size.width < 1180) {
        await tester.tap(find.text('Conversations').last);
        await tester.pumpAndSettle();
        expect(find.text('Your conversations'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'conversations-${size.width.toInt()}');
        await tester.tap(find.text('Search').last);
        await tester.pumpAndSettle();
        expect(find.text('Recent searches'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'search-${size.width.toInt()}');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('SET-01 Settings persists Urdu and offline selection', (
    tester,
  ) async {
    final store = MemoryStore();
    final controller = CaptionController(
      engine: FakeSpeechEngine(),
      store: store,
    );
    await tester.pumpWidget(ListenCareApp(controller: controller));
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text('اردو').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Offline only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offline only'));
    await tester.pumpAndSettle();
    expect(store.state.language, CaptionLanguage.urdu);
    expect(store.state.mode, RecognitionMode.offline);
    await tester.ensureVisible(find.byType(Slider));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(store.state.captionSize, greaterThan(22));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('LIB-03 search filters saved text and opens complete captions', (
    tester,
  ) async {
    final store = MemoryStore()
      ..state = SavedState(
        conversations: [
          Conversation(
            id: '1',
            text: 'Discuss project plans',
            language: CaptionLanguage.english,
            createdAt: DateTime(2026, 10, 12),
            durationSeconds: 60,
          ),
          Conversation(
            id: '2',
            text: 'سلام آپ کیسے ہیں',
            language: CaptionLanguage.urdu,
            createdAt: DateTime(2026, 10, 12),
            durationSeconds: 40,
          ),
        ],
      );
    final controller = CaptionController(
      engine: FakeSpeechEngine(),
      store: store,
    );
    await controller.load();
    await tester.pumpWidget(ListenCareApp(controller: controller));
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'project');
    await tester.pumpAndSettle();
    expect(find.text('Discuss project plans'), findsOneWidget);
    expect(find.text('سلام آپ کیسے ہیں'), findsNothing);
    await tester.ensureVisible(find.text('Discuss project plans'));
    await tester.tap(find.text('Discuss project plans'));
    await tester.pumpAndSettle();
    expect(find.text('Conversation'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('CAP-09 Urdu caption direction and large text remain readable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final engine = FakeSpeechEngine();
    final controller = CaptionController(engine: engine, store: MemoryStore());
    await controller.updateSettings(
      language: CaptionLanguage.urdu,
      captionSize: 36,
    );
    await tester.pumpWidget(ListenCareApp(controller: controller));
    await controller.start();
    engine.emit('سلام آپ کیسے ہیں');
    await controller.stop();
    await tester.pumpAndSettle();
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(text.textDirection, TextDirection.rtl);
    expect(text.style!.fontSize, 36);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('CAP-09 narrow screens support large OS text and Settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = CaptionController(
      engine: FakeSpeechEngine(),
      store: MemoryStore(),
    );
    await tester.pumpWidget(ListenCareApp(controller: controller));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Settings').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
