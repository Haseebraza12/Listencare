import 'package:flutter/material.dart';
import 'features/captions/application/caption_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class ListenCareApp extends StatelessWidget {
  const ListenCareApp({super.key, required this.controller});
  final CaptionController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ListenCare',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: HomeScreen(controller: controller),
  );
}
