import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/cards_row_type.dart';
import 'package:gwent_helper_flutter/features/game/widgets/add_card_dialog.dart';
import 'package:gwent_helper_flutter/l10n/app_localizations.dart';
import 'package:gwent_helper_flutter/l10n/domain_localizations.dart';

void main() {
  // Pixel 8 held in landscape — the only orientation this app supports.
  const physicalSize = Size(2400, 1080);
  const devicePixelRatio = 2.625;

  Future<dynamic> pumpAndOpenDialog(WidgetTester tester) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);

    dynamic result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showDialog(
                  context: context,
                  builder: (_) =>
                      const AddCardDialog(rowType: CardsRowType.closeCombat),
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

  group('AddCardDialog', () {
    testWidgets(
      '''
      Given the dialog is opened on a landscape phone
      When it is rendered
      Then every ability fits on screen and nothing overflows
      ''',
      (tester) async {
        // When
        await pumpAndOpenDialog(tester);
        final context = tester.element(find.byType(AddCardDialog));

        // Then
        for (final ability in Ability.values) {
          expect(
            find.text(localizedAbilityName(context, ability)),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given points and an ability are chosen
      When ADD is tapped
      Then the created card carries both
      ''',
      (tester) async {
        // Given
        final getResult = await pumpAndOpenDialog(tester);
        final context = tester.element(find.byType(AddCardDialog));
        await tester.tap(
          find.text(localizedAbilityName(context, Ability.hero)),
        );
        await tester.pump();

        // When
        await tester.tap(find.text('ADD'));
        await tester.pumpAndSettle();

        // Then
        final card = getResult();
        expect(card.points, 0);
        expect(card.abilities, contains(Ability.hero));
      },
    );

    testWidgets(
      '''
      Given the dialog is open
      When CANCEL is tapped
      Then no card is returned
      ''',
      (tester) async {
        // Given
        final getResult = await pumpAndOpenDialog(tester);

        // When
        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();

        // Then
        expect(getResult(), isNull);
      },
    );
  });
}
