import 'package:flutter/material.dart';

// DESIGN.md tokens: physical-board materials edition.
// Felt table + wooden rim + ivory board face + jewel house colors.
abstract final class LudoColors {
  static const cream = Color(0xFFFFF8E1);
  static const track = Colors.white;
  static const safeStar = Color(0xFFFFD54F);
  static const ink = Color(0xFF212121);

  // Physical materials.
  static const felt = Color(0xFF1B5E43); // table felt (game backdrop)
  static const feltDark = Color(0xFF12402E); // felt vignette edge
  static const wood = Color(0xFF8D5A2B); // board rim
  static const woodDark = Color(0xFF5D3A17); // rim outer edge / grain
  static const ivory = Color(0xFFFFF6E3); // board face
  static const cellInset = Color(0xFFF3E7C8); // track cell fill
  static const cellEdge = Color(0xFFB08D4F); // track cell border
  static const gold = Color(0xFFFFC107); // safe stars, winner accents
  static const diceFace = Color(0xFFFFFEFA);
  static const dicePip = Color(0xFF212121);

  static const List<Color> houses = [
    Color(0xFFE53935), // P1 red
    Color(0xFF43A047), // P2 green
    Color(0xFFFBC02D), // P3 yellow
    Color(0xFF1E88E5), // P4 blue
  ];

  static Color house(int corner) => houses[corner % houses.length];

  /// Darkened edge shade for glossy tokens / banners.
  static Color houseDark(int corner) {
    final c = house(corner);
    return Color.fromARGB(0xFF, (c.r * 0.62 * 255).round(),
        (c.g * 0.62 * 255).round(), (c.b * 0.62 * 255).round());
  }
}

ThemeData ludoTheme() {
  const ink = LudoColors.ink;
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFE53935));
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: LudoColors.felt,
    appBarTheme: const AppBarTheme(
      backgroundColor: LudoColors.feltDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
      bodyMedium: TextStyle(fontSize: 14, color: ink),
      bodySmall: TextStyle(fontSize: 12, color: ink),
    ),
    cardTheme: const CardThemeData(
      color: LudoColors.ivory,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      elevation: 4,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
