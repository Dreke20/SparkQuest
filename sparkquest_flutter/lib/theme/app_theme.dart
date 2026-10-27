import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette
  static const Color bgDeep = Color(0xFF0B0F1A);
  static const Color bgSurface = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1A2235);
  static const Color bgInput = Color(0xFF1E293B);

  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color sparkCoral = Color(0xFFFF3F6C);
  static const Color questGold = Color(0xFFFFB800);
  static const Color electricViolet = Color(0xFF7B2FFF);
  static const Color emeraldGreen = Color(0xFF10B981);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      primaryColor: sparkCoral,
      colorScheme: const ColorScheme.dark(
        primary: sparkCoral,
        secondary: neonCyan,
        surface: bgSurface,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
        fontFamily: 'Roboto',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDeep,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: neonCyan,
        unselectedItemColor: textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
    );
  }
}
