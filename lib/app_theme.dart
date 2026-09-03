import 'package:flutter/material.dart';

abstract class AppTheme {
  /// Scaffold behind the HUD.
  static const background = Color(0xFF0D0F0C);

  /// Sidebar, score rows, chips and dialog surfaces.
  static const panel = Color(0xFF141811);

  /// Hairlines and idle borders.
  static const olive = Color(0xFF6B7C3A);

  /// Titles, selected state and primary actions.
  static const gold = Color(0xFFC8A84B);

  /// Body text and icons on dark surfaces.
  static const cream = Color(0xFFD4C48A);

  /// Scorch highlights and destructive actions.
  static const _error = Color(0xFFE31829);
  static const _onError = Color(0xFFFFFFFF);
  static const _errorContainer = Color(0xFF4A0A11);
  static const _onErrorContainer = Color(0xFFFFD9D6);

  static const _radius = BorderRadius.all(Radius.circular(4));

  /// Text and icon color for content placed on cards.
  ///
  /// Temporary alias kept while the scores UI still overrides its own text
  /// colors; it disappears once those widgets read the tokens directly.
  static const onLightCard = cream;

  static final data = _hudTheme();

  static ThemeData _hudTheme() {
    // The HUD palette has a single gold, so the container roles reuse it
    // instead of inventing shades the design does not define.
    final base = ThemeData(
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: background,
        primaryContainer: gold,
        onPrimaryContainer: background,
        secondary: gold,
        onSecondary: background,
        secondaryContainer: gold,
        onSecondaryContainer: background,
        tertiary: gold,
        onTertiary: background,
        tertiaryContainer: gold,
        onTertiaryContainer: background,
        surface: panel,
        onSurface: cream,
        onSurfaceVariant: cream,
        surfaceDim: background,
        surfaceBright: panel,
        surfaceContainerLowest: background,
        surfaceContainerLow: panel,
        surfaceContainer: panel,
        surfaceContainerHigh: panel,
        surfaceContainerHighest: panel,
        outline: olive,
        outlineVariant: olive,
        inverseSurface: cream,
        onInverseSurface: background,
        inversePrimary: gold,
        surfaceTint: Colors.transparent,
        error: _error,
        onError: _onError,
        errorContainer: _errorContainer,
        onErrorContainer: _onErrorContainer,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme
          .apply(bodyColor: cream, displayColor: cream)
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: 'Vollkorn',
              fontWeight: FontWeight.w700,
              color: gold,
              fontSize: 48,
            ),
            headlineLarge: const TextStyle(
              fontFamily: 'Vollkorn',
              fontWeight: FontWeight.w700,
              color: gold,
              fontSize: 32,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'Vollkorn',
              fontWeight: FontWeight.w700,
              color: gold,
              fontSize: 24,
            ),
          ),
      cardTheme: const CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: olive),
          borderRadius: _radius,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: panel,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Vollkorn',
          color: gold,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: olive),
          borderRadius: _radius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: background,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: _radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cream,
          side: const BorderSide(color: gold),
          shape: const RoundedRectangleBorder(borderRadius: _radius),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? gold : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(background),
        side: const BorderSide(color: olive, width: 2),
        shape: const RoundedRectangleBorder(borderRadius: _radius),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: gold,
        inactiveTrackColor: olive,
        thumbColor: gold,
        valueIndicatorColor: panel,
      ),
    );
  }
}
