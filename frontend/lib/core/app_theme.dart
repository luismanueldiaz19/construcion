import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF1A1C1E); // Dark Grey from logo
  static const accentColor = Color(0xFFE31E24); // Vibrant Red from logo
  static const backgroundColor = Color(0xFFF8F9FA);
  static const cardColor = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: accentColor, // Use Red as primary for buttons/links
      secondary: primaryColor, // Dark grey as secondary
      surface: backgroundColor,
    ),
    // scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      // backgroundColor:
      //     Colors.transparent, // Also make AppBar transparent by default
      // foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: primaryColor,
      selectedIconTheme: IconThemeData(color: accentColor),
      unselectedIconTheme: IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: TextStyle(
        color: accentColor,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(color: Colors.white70),
    ),
  );
}
