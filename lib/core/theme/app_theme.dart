import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF1DB954);
  static const Color _darkSurface = Color(0xFF121212);
  static const Color _darkCard = Color(0xFF1E1E1E);
  static const Color _lightSurface = Color(0xFFF5F5F5);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _darkSurface,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: _darkSurface,
        onSurface: Colors.white,
      ),
      cardColor: _darkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkCard,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: _darkCard,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryColor,
      scaffoldBackgroundColor: _lightSurface,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _primaryColor,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }
}
