import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/main.dart';

void main() {
  group('Localization', () {
    // The home screen's PLAY button label in each supported non-English
    // locale — cheap, broad coverage that every ARB file actually loads
    // and resolves, without asserting every string in every language.
    const playLabelByLocale = {
      'de': 'SPIELEN',
      'es': 'JUGAR',
      'fr': 'JOUER',
      'it': 'GIOCA',
      'nl': 'SPELEN',
      'pl': 'GRAJ',
      'pt': 'JOGAR',
      'uk': 'ГРАТИ',
    };

    for (final entry in playLabelByLocale.entries) {
      testWidgets(
        '''
        Given the app locale is "${entry.key}"
        When the app launches
        Then the home screen renders in that language, not English
        ''',
        (tester) async {
          // When
          await tester.pumpWidget(GwentHelperApp(locale: Locale(entry.key)));
          await tester.pumpAndSettle();

          // Then
          expect(tester.takeException(), isNull);
          expect(find.text(entry.value), findsOneWidget);
          expect(find.text('PLAY'), findsNothing);
        },
      );
    }

    testWidgets(
      '''
      Given the app locale is Ukrainian
      When the app launches
      Then player names are also translated, not just the button labels
      ''',
      (tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp(locale: Locale('uk')));
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Гравець 1'), findsOneWidget);
        expect(find.text('Гравець 2'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given the app locale is one this app does not support (e.g. Japanese)
      When the app launches
      Then it falls back to English rather than crashing or picking whichever
      supported locale happens to sort first
      ''',
      (tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp(locale: Locale('ja')));
        await tester.pumpAndSettle();

        // Then
        expect(tester.takeException(), isNull);
        expect(find.text('PLAY'), findsOneWidget);
      },
    );
  });
}
