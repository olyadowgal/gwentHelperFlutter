import 'package:flutter/material.dart';

abstract class AppTheme {
  static const _slate = Color(0xFF263238);

  /// Text and icon color for content placed on the app's light cards, which
  /// cannot use `onSurface` because that is white in this dark color scheme.
  static const onLightCard = _slate;

  static final data = ThemeData(
    scaffoldBackgroundColor: _slate,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1FAA83),
      onPrimary: _slate,
      primaryContainer: Color(0xFF5FDCB3),
      onPrimaryContainer: _slate,
      secondary: Color(0xFFFFCA28),
      onSecondary: _slate,
      secondaryContainer: Color(0xFFC79A00),
      onSecondaryContainer: _slate,
      surface: Color(0xFF37474F),
      onSurface: Colors.white,
      outline: Color(0xFF6C6E6F),
      error: Color(0xFFE31829),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Vollkorn',
        fontWeight: FontWeight.w700,
        color: Color(0xFF5FDCB3),
        fontSize: 48,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Vollkorn',
        fontWeight: FontWeight.w700,
        color: Color(0xFF5FDCB3),
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Vollkorn',
        fontWeight: FontWeight.w700,
        color: Color(0xFF5FDCB3),
        fontSize: 24,
      ),
    ),
    cardTheme: const CardThemeData(color: Colors.white, elevation: 6),
    useMaterial3: true,
  );
}
