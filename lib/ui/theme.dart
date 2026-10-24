import 'package:flutter/material.dart';

abstract final class EqualiColors {
  static const background = Color(0xFFE9F0F7);
  static const primary = Color(0xFF5B66F2);
  static const text = Color(0xFF303745);
  static const icon = Color(0xFF596882);
  static const muted = Color(0xFF8F9BB2);
  static const line = Color(0xFFCFDBE8);
}

ThemeData equaliTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'OpenSans',
  scaffoldBackgroundColor: EqualiColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: EqualiColors.primary,
    surface: EqualiColors.background,
    onSurface: EqualiColors.text,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 14, color: EqualiColors.text),
    bodyMedium: TextStyle(fontSize: 14, color: EqualiColors.text),
    bodySmall: TextStyle(fontSize: 12, color: EqualiColors.muted),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: EqualiColors.text),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EqualiColors.text),
  ),
  sliderTheme: const SliderThemeData(
    trackHeight: 4,
    activeTrackColor: EqualiColors.primary,
    inactiveTrackColor: EqualiColors.line,
    thumbColor: Colors.white,
    overlayColor: Color(0x185B66F2),
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: EqualiColors.text,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dividerColor: Colors.white,
);
