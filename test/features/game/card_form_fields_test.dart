import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/features/game/widgets/card_form_fields.dart';

void main() {
  Future<void> pumpFields(
    WidgetTester tester, {
    required List<Ability> selectedAbilities,
    required ValueChanged<Ability> onAbilityToggled,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          child: CardFormFields(
            points: 5,
            onPointsChanged: (_) {},
            selectedAbilities: selectedAbilities,
            onAbilityToggled: onAbilityToggled,
          ),
        ),
      ),
    ),
  );

  group('CardFormFields', () {
    testWidgets(
      '''
      Given a 700px-wide host
      When it is rendered
      Then every ability appears without needing to scroll
      ''',
      (tester) async {
        // When
        await pumpFields(
          tester,
          selectedAbilities: const [],
          onAbilityToggled: (_) {},
        );

        // Then
        for (final ability in Ability.values) {
          expect(find.text(ability.displayName), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '''
      Given abilities laid out wider than one column
      When rendered
      Then at least two tiles share the same row
      ''',
      (tester) async {
        // When
        await pumpFields(
          tester,
          selectedAbilities: const [],
          onAbilityToggled: (_) {},
        );

        // Then
        final firstTop = tester
            .getTopLeft(find.text(Ability.values[0].displayName))
            .dy;
        final secondTop = tester
            .getTopLeft(find.text(Ability.values[1].displayName))
            .dy;
        expect(secondTop, closeTo(firstTop, 5));
      },
    );

    testWidgets(
      '''
      Given an unselected ability
      When its tile is tapped
      Then it is reported toggled on
      ''',
      (tester) async {
        // Given
        Ability? toggled;
        await pumpFields(
          tester,
          selectedAbilities: const [],
          onAbilityToggled: (ability) => toggled = ability,
        );

        // When
        await tester.tap(find.text(Ability.hero.displayName));
        await tester.pump();

        // Then
        expect(toggled, Ability.hero);
      },
    );
  });
}
