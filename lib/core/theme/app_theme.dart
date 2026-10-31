import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const ink = Color(0xFF263D37);
  static const coral = Color(0xFFE47B5F);
  static const cream = Color(0xFFF8F6F0);
  static const muted = Color(0xFF6D7C76);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: coral,
      primary: coral,
      secondary: ink,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: coral,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

