import 'package:flutter/material.dart';

class AppTheme {
  // Color constants - change these to modify the entire app theme
  static const Color primaryColor = Colors.black;
  static const Color secondaryColor = Colors.white;
  static const Color surfaceColor = Colors.black;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white; // For less prominent text
  static const Color buttonBackground = Colors.white;
  static const Color buttonForeground = Colors.black;

  // Opacity values
  static const double textSecondaryOpacity = 0.7;
  static const double textTertiaryOpacity = 0.5;
  static const double borderOpacity = 0.2;
  static const double containerOpacity = 0.1;
  static const double selectedContainerOpacity = 0.2;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: textPrimary,
        onSecondary: buttonForeground,
        onSurface: textPrimary,
        error: primaryColor,
        onError: textPrimary,
      ),
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: textPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textPrimary.withOpacity(borderOpacity)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        hintStyle: TextStyle(
          color: textPrimary.withOpacity(textTertiaryOpacity),
        ),
        labelStyle: TextStyle(color: textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textPrimary),
        displayMedium: TextStyle(color: textPrimary),
        displaySmall: TextStyle(color: textPrimary),
        headlineLarge: TextStyle(color: textPrimary),
        headlineMedium: TextStyle(color: textPrimary),
        headlineSmall: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary),
        titleMedium: TextStyle(color: textPrimary),
        titleSmall: TextStyle(color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(
          color: textPrimary.withOpacity(textSecondaryOpacity),
        ),
        labelLarge: TextStyle(color: textPrimary),
        labelMedium: TextStyle(color: textPrimary),
        labelSmall: TextStyle(
          color: textPrimary.withOpacity(textTertiaryOpacity),
        ),
      ),
    );
  }
}
