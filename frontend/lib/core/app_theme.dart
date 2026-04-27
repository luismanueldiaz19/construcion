import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFF003366); // Deep Construction Blue
  static const accentColor = Color(0xFFFFA500); // Construction Orange
  static const backgroundColor = Color(0xFFF5F7FA);
  static const cardColor = Colors.white;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
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
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: primaryColor,
      selectedIconTheme: IconThemeData(color: accentColor),
      unselectedIconTheme: IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: TextStyle(color: accentColor, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: TextStyle(color: Colors.white70),
    ),
  );
}
