import 'package:flutter/material.dart';

abstract final class Palette {
  static const ink = Color(0xFF181610);
  static const muted = Color(0xFF77737E);
  static const purple = Color(0xFFA879E9);
  static const pink = Color(0xFFE6A9C5);
  static const gold = Color(0xFFFFD68B);
  static const lavender = Color(0xFFF5F0FE);
  static const line = Color(0xFFE8E5EA);
  static const gradient = LinearGradient(
    colors: [purple, pink, gold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
