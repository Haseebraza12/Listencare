// Run: flutter test --no-pub tool/generate_brand.dart
// Renders the code-native vector mark used by the app into a launcher asset.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listencare/widgets/brand_mark.dart';

void main() {
  testWidgets('Render canonical ListenCare brand mark', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: Color(0xFFF7F2FF),
            child: BrandMark(size: 1024),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('assets/brand').create(recursive: true);
      await File(
        'assets/brand/listencare.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
