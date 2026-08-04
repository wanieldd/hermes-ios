import 'package:flutter/material.dart';

class HermesTheme {
  // Brand colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4A42E0);
  static const Color accent = Color(0xFF00D9FF);

  // Neutrals
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);
  static const Color surfaceCard = Color(0xFF2A2A45);
  static const Color border = Color(0xFF3A3A55);
  static const Color borderLight = Color(0xFF4A4A65);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFFA0A0C0);
  static const Color textMuted = Color(0xFF707090);
  static const Color textInverse = Color(0xFF0F0F1A);

  // Semantic
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF60A5FA);

  // Chat roles
  static const Color userBubble = Color(0xFF6C63FF);
  static const Color assistantBubble = Color(0xFF2A2A45);
  static const Color systemBubble = Color(0xFF1A3A2A);
  static const Color toolCallBg = Color(0xFF1E1E35);

  // Thinking block
  static const Color thinkingBg = Color(0xFF1A1A2E);
  static const Color thinkingBorder = Color(0xFF3A3A55);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: textInverse,
        onSecondary: textInverse,
        onSurface: textPrimary,
        onError: textInverse,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      iconTheme: const IconThemeData(color: textSecondary),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // System theme aware
  static ThemeData get lightTheme {
    // For now, return dark. A light theme can be added later.
    return darkTheme;
  }
}