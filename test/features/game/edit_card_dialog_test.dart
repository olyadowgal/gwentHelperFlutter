import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart';
import 'package:gwent_helper_flutter/features/game/widgets/edit_card_dialog.dart';

void main() {
  // Pixel 8 held in landscape — the only orientation this app supports.
  const physicalSize = Size(2400, 1080);
  const devicePixelRatio = 2.625;

  Future<dynamic> pumpAndOpenDialog(WidgetTester tester, Card card) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);

    dynamic result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDialog(
                  context: context,
                  builder: (_) => EditCardDialog(card: card),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  group('EditCardDialog', () {
    testWidgets(
      '''
      Given the dialog is opened on a landscape phone
      When it is rendered
      Then every ability fits on screen and nothing overflows
      ''',
      (tester) async {
        // Given
        final card = Card(points: 4, abilities: const []);

        // When
        await pumpAndOpenDialog(tester, card);

        // Then
        for (final ability in Ability.values) {
          expect(find.text(ability.displayName), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given an existing card with Tight Bond
      When SAVE is tapped without changes
      Then the returned result keeps the same points and ability
      ''',
      (tester) async {
        // Given
        final card = Card(points: 7, abilities: const [Ability.tightBond]);
        final getResult = await pumpAndOpenDialog(tester, card);

        // When
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Then
        final result = getResult() as EditCardSave;
        expect(result.card.points, 7);
        expect(result.card.abilities, contains(Ability.tightBond));
      },
    );

    testWidgets(
      '''
      Given the dialog is open
      When DELETE is tapped
      Then an EditCardDelete result is returned
      ''',
      (tester) async {
        // Given
        final card = Card(points: 3, abilities: const []);
        final getResult = await pumpAndOpenDialog(tester, card);

        // When
        await tester.tap(find.byKey(EditCardDialog.deleteButtonKey));
        await tester.pumpAndSettle();

        // Then
        expect(getResult(), isA<EditCardDelete>());
      },
    );
  });
}
