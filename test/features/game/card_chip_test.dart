import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/domain/models/ability.dart';
import 'package:gwent_helper_flutter/domain/models/card.dart' as domain;
import 'package:gwent_helper_flutter/features/game/widgets/card_chip.dart';

void main() {
  Future<void> pumpChip(
    WidgetTester tester, {
    required bool isScorchTarget,
    List<Ability> abilities = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: Scaffold(
          body: CardChip(
            card: domain.Card(cardId: 'c1', points: 7, abilities: abilities),
            displayPoints: 7,
            onLongPress: () {},
            isScorchTarget: isScorchTarget,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The [Material] a [Card] paints itself with, which falls back to the card
  /// theme when the widget does not set a shape or color of its own.
  Material paintedCard(WidgetTester tester) => tester.widget<Material>(
    find
        .descendant(of: find.byType(Card), matching: find.byType(Material))
        .first,
  );

  RoundedRectangleBorder paintedShape(WidgetTester tester) =>
      paintedCard(tester).shape! as RoundedRectangleBorder;

  /// The rounding the app gives every card, used as the reference the chip
  /// has to match.
  Future<BorderRadiusGeometry?> appCardRadius(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: const Scaffold(body: Card(child: SizedBox.shrink())),
      ),
    );
    return paintedShape(tester).borderRadius;
  }

  group('CardChip', () {
    testWidgets(
      '''
      Given a chip highlighted as a Scorch target
      When it is rendered
      Then its corners are rounded like every other card
      ''',
      (tester) async {
        // Given
        final expectedRadius = await appCardRadius(tester);

        // When
        await pumpChip(tester, isScorchTarget: true);

        // Then
        expect(paintedShape(tester).borderRadius, expectedRadius);
      },
    );

    testWidgets(
      '''
      Given an unhighlighted chip
      When it is rendered
      Then its corners are rounded like every other card
      ''',
      (tester) async {
        // Given
        final expectedRadius = await appCardRadius(tester);

        // When
        await pumpChip(tester, isScorchTarget: false);

        // Then
        expect(paintedShape(tester).borderRadius, expectedRadius);
      },
    );

    testWidgets(
      '''
      Given a chip highlighted as a Scorch target
      When it is rendered
      Then the border uses the error color
      ''',
      (tester) async {
        // When
        await pumpChip(tester, isScorchTarget: true);

        // Then
        final side = paintedShape(tester).side;
        expect(side.color, AppTheme.data.colorScheme.error);
        expect(side.width, greaterThan(0));
      },
    );

    testWidgets(
      '''
      Given an ordinary unit chip
      When it is rendered
      Then it is a plain parchment card face with an olive border
      ''',
      (tester) async {
        // When
        await pumpChip(tester, isScorchTarget: false);

        // Then
        expect(paintedCard(tester).color, AppTheme.cardFace);
        expect(paintedShape(tester).side.color, AppTheme.olive);
        expect(paintedShape(tester).side.width, 1.5);
      },
    );

    testWidgets(
      '''
      Given a hero chip
      When it is rendered
      Then it takes the warmer cream card face and a gold border
      ''',
      (tester) async {
        // When
        await pumpChip(
          tester,
          isScorchTarget: false,
          abilities: const [Ability.hero],
        );

        // Then
        expect(paintedCard(tester).color, AppTheme.cream);
        expect(paintedShape(tester).side.color, AppTheme.gold);
        expect(paintedShape(tester).side.width, 1.5);
      },
    );

    testWidgets(
      '''
      Given a hero chip highlighted as a Scorch target
      When it is rendered
      Then the Scorch border wins but the shape is unchanged
      ''',
      (tester) async {
        // Given
        await pumpChip(
          tester,
          isScorchTarget: false,
          abilities: const [Ability.hero],
        );
        final heroShape = paintedShape(tester);

        // When
        await pumpChip(
          tester,
          isScorchTarget: true,
          abilities: const [Ability.hero],
        );

        // Then
        expect(
          paintedShape(tester).side.color,
          AppTheme.data.colorScheme.error,
        );
        expect(paintedShape(tester).borderRadius, heroShape.borderRadius);
      },
    );

    testWidgets(
      '''
      Given any chip
      When its point total is rendered
      Then it stays bold, large enough to read, and dark ink on the cream face
      ''',
      (tester) async {
        // When
        await pumpChip(tester, isScorchTarget: false);

        // Then
        final style = tester.widget<Text>(find.text('7')).style!;
        expect(style.fontWeight, FontWeight.bold);
        expect(style.fontSize, greaterThanOrEqualTo(13));
        expect(style.color, AppTheme.background);
      },
    );
  });
}
