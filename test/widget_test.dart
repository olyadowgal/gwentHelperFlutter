import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/main.dart';

void main() {
  group('GwentHelperApp', () {
    testWidgets(
      '''
      Given the app
      When it is launched
      Then player name inputs are shown
      ''',
      (WidgetTester tester) async {
        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('Player 2'), findsOneWidget);
      },
    );

    testWidgets(
      '''
      Given a portrait phone screen
      When the app is launched before the orientation lock applies
      Then nothing overflows
      ''',
      (WidgetTester tester) async {
        // Given
        tester.view
          ..physicalSize = const Size(1080, 2400)
          ..devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);

        // When
        await tester.pumpWidget(const GwentHelperApp());
        await tester.pumpAndSettle();

        // Then
        expect(tester.takeException(), isNull);
      },
    );
  });
}
