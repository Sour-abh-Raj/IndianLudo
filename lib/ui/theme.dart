import 'package:flutter/material.dart';

// DESIGN.md tokens.
abstract final class LudoColors {
  static const cream = Color(0xFFFFF8E1);
  static const track = Colors.white;
  static const safeStar = Color(0xFFFFD54F);
  static const ink = Color(0xFF212121);
  static const List<Color> houses = [
    Color(0xFFE53935), // P1 red
    Color(0xFF43A047), // P2 green
    Color(0xFFFBC02D), // P3 yellow
    Color(0xFF1E88E5), // P4 blue
  ];

  static Color house(int corner) => houses[corner % houses.length];
}

ThemeData ludoTheme() {
  const ink = LudoColors.ink;
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFE53935));
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: LudoColors.cream,
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
      bodyMedium: TextStyle(fontSize: 14, color: ink),
      bodySmall: TextStyle(fontSize: 12, color: ink),
    ),
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
