import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema global do TranCity baseado em Material Design 3.
abstract final class AppTheme {
  /// Tema claro do aplicativo.
  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      primary: kPrimaryColor,
      error: kErrorColor,
      surface: kSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: kBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: kBackgroundColor,
        foregroundColor: kTextPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kSurfaceColor,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: kTextSecondaryColor,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: kSurfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
