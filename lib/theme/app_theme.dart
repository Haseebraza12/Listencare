import 'package:flutter/material.dart';
import 'palette.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    fontFamilyFallback: const ['NotoNaskhArabic'],
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.purple,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Palette.ink, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: Palette.ink, fontSize: 14, height: 1.5),
      bodySmall: TextStyle(color: Palette.muted, fontSize: 12, height: 1.5),
      titleLarge: TextStyle(
        color: Palette.ink,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
      ),
      titleMedium: TextStyle(
        color: Palette.ink,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
    ),
    dividerColor: Palette.line,
    splashFactory: InkSparkle.splashFactory,
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      hintStyle: TextStyle(color: Palette.muted, fontSize: 14),
    ),
  );
}
