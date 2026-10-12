import 'package:flutter/material.dart';
import 'app.dart';
import 'features/captions/application/caption_controller.dart';
import 'features/captions/data/device_speech_engine.dart';
import 'features/library/data/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = CaptionController(
    engine: DeviceSpeechEngine(),
    store: PreferencesStore(),
  );
  await controller.load();
  runApp(ListenCareApp(controller: controller));
}
