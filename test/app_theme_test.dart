import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';

/// WCAG contrast ratio between two opaque colors.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (max(first, second) + 0.05) / (min(first, second) + 0.05);
}

void main() {
  group('AppTheme', () {
    test(
      '''
      Given the HUD palette
      When the tokens are read
      Then they are the approved near-black, olive, and gold colors
      ''',
      () {
        // Then
        expect(AppTheme.background, const Color(0xFF0D0F0C));
        expect(AppTheme.panel, const Color(0xFF141811));
        expect(AppTheme.olive, const Color(0xFF6B7C3A));
        expect(AppTheme.gold, const Color(0xFFC8A84B));
        expect(AppTheme.cream, const Color(0xFFD4C48A));
      },
    );

    test(
      '''
      Given the app theme
      When its surfaces are read
      Then the scaffold is the background token and cards are the panel token
      ''',
      () {
        // Then
        expect(AppTheme.data.scaffoldBackgroundColor, AppTheme.background);
        expect(AppTheme.data.cardTheme.color, AppTheme.panel);
      },
    );

    test(
      '''
      Given the HUD palette
      When text and chrome colors are paired with the surfaces behind them
      Then every pairing meets the 4.5:1 readability floor
      ''',
      () {
        // Given
        final scheme = AppTheme.data.colorScheme;

        // Then
        expect(
          _contrastRatio(AppTheme.cream, AppTheme.background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(AppTheme.cream, AppTheme.panel),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(AppTheme.gold, AppTheme.background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(AppTheme.gold, AppTheme.panel),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(scheme.onError, scheme.error),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(scheme.onErrorContainer, scheme.errorContainer),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test(
      '''
      Given the app theme
      When the color scheme is read
      Then primary, secondary, surface, and outline roles use the HUD tokens
      ''',
      () {
        // Given
        final scheme = AppTheme.data.colorScheme;

        // Then
        expect(scheme.brightness, Brightness.dark);
        expect(scheme.primary, AppTheme.gold);
        expect(scheme.onPrimary, AppTheme.background);
        expect(scheme.primaryContainer, AppTheme.gold);
        expect(scheme.onPrimaryContainer, AppTheme.background);
        expect(scheme.secondary, AppTheme.gold);
        expect(scheme.onSecondary, AppTheme.background);
        expect(scheme.secondaryContainer, AppTheme.gold);
        expect(scheme.onSecondaryContainer, AppTheme.background);
        expect(scheme.surface, AppTheme.panel);
        expect(scheme.onSurface, AppTheme.cream);
        expect(scheme.onSurfaceVariant, AppTheme.cream);
        expect(scheme.outline, AppTheme.olive);
        expect(scheme.tertiary, AppTheme.gold);
        expect(scheme.onTertiary, AppTheme.background);
        expect(scheme.inversePrimary, AppTheme.gold);
        expect(scheme.surfaceTint, Colors.transparent);
        expect(scheme.surfaceContainerLowest, AppTheme.background);
        expect(scheme.surfaceContainerLow, AppTheme.panel);
        expect(scheme.surfaceContainer, AppTheme.panel);
        expect(scheme.surfaceContainerHigh, AppTheme.panel);
        expect(scheme.surfaceContainerHighest, AppTheme.panel);
      },
    );

    test(
      '''
      Given the Scorch and destructive actions
      When the error color is read
      Then it stays a strong red rather than an olive or gold tint
      ''',
      () {
        // Given
        final error = AppTheme.data.colorScheme.error;

        // Then
        expect(error.r, greaterThan(0.7));
        expect(error.g, lessThan(0.3));
        expect(error.b, lessThan(0.3));
      },
    );

    test(
      '''
      Given the dark card theme
      When a card is described
      Then it is a flat panel with an olive hairline and 4px corners
      ''',
      () {
        // Given
        final cardTheme = AppTheme.data.cardTheme;

        // Then
        expect(cardTheme.elevation, 0);
        final shape = cardTheme.shape! as RoundedRectangleBorder;
        expect(shape.side.color, AppTheme.olive);
        expect(shape.side.width, 1);
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(4)));
      },
    );

    test(
      '''
      Given the dark dialog theme
      When a dialog is described
      Then it is a panel with a gold Vollkorn title and readable cream content
      ''',
      () {
        // Given
        final dialogTheme = AppTheme.data.dialogTheme;

        // Then
        expect(dialogTheme.backgroundColor, AppTheme.panel);
        expect(dialogTheme.elevation, 0);
        final title = dialogTheme.titleTextStyle!;
        expect(title.fontFamily, 'Vollkorn');
        expect(title.color, AppTheme.gold);
        expect(title.fontSize, 24);
        expect(title.fontWeight, FontWeight.w700);
        expect(AppTheme.data.textTheme.bodyMedium!.color, AppTheme.cream);
        final shape = dialogTheme.shape! as RoundedRectangleBorder;
        expect(shape.side.color, AppTheme.olive);
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(4)));
      },
    );

    test(
      '''
      Given the text theme
      When display and body styles are compared
      Then only display and headline styles use Vollkorn and body text is cream
      ''',
      () {
        // Given
        final textTheme = AppTheme.data.textTheme;

        // Then
        for (final display in [
          textTheme.displayLarge!,
          textTheme.headlineLarge!,
          textTheme.headlineMedium!,
        ]) {
          expect(display.fontFamily, 'Vollkorn');
          expect(display.color, AppTheme.gold);
          expect(display.fontWeight, FontWeight.w700);
        }
        for (final body in [
          textTheme.bodyLarge!,
          textTheme.bodyMedium!,
          textTheme.bodySmall!,
          textTheme.titleMedium!,
          textTheme.labelLarge!,
        ]) {
          expect(body.fontFamily, isNot('Vollkorn'));
          expect(body.color, AppTheme.cream);
        }
      },
    );

    test(
      '''
      Given a primary action
      When the elevated button theme is read
      Then it is filled gold with dark labels and no shadow
      ''',
      () {
        // Given
        final style = AppTheme.data.elevatedButtonTheme.style!;

        // Then
        expect(style.backgroundColor!.resolve({}), AppTheme.gold);
        expect(style.foregroundColor!.resolve({}), AppTheme.background);
        expect(style.elevation!.resolve({}), 0);
      },
    );

    test(
      '''
      Given a secondary action
      When the text button theme is read
      Then it is a cream label inside a gold outline
      ''',
      () {
        // Given
        final style = AppTheme.data.textButtonTheme.style!;

        // Then
        expect(style.foregroundColor!.resolve({}), AppTheme.cream);
        final side = style.side!.resolve({})!;
        expect(side.color, AppTheme.gold);
        expect(side.width, greaterThan(0));
      },
    );

    test(
      '''
      Given the selection controls
      When checkbox and slider defaults are read
      Then selected state is gold and idle chrome is olive
      ''',
      () {
        // Given
        final checkboxTheme = AppTheme.data.checkboxTheme;
        final sliderTheme = AppTheme.data.sliderTheme;

        // Then
        expect(
          checkboxTheme.fillColor!.resolve({WidgetState.selected}),
          AppTheme.gold,
        );
        expect(checkboxTheme.checkColor!.resolve({}), AppTheme.background);
        expect(checkboxTheme.side!.color, AppTheme.olive);
        expect(sliderTheme.activeTrackColor, AppTheme.gold);
        expect(sliderTheme.thumbColor, AppTheme.gold);
        expect(sliderTheme.inactiveTrackColor, AppTheme.olive);
      },
    );
  });
}
