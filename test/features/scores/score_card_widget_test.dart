import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/app_theme.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';
import 'package:gwent_helper_flutter/features/scores/resources/scores_strings.dart';
import 'package:gwent_helper_flutter/features/scores/widgets/score_card_widget.dart';

/// WCAG contrast ratio between two opaque colors.
double _contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return (max(first, second) + 0.05) / (min(first, second) + 0.05);
}

GameScore buildScore({
  String firstPlayer = 'Alice',
  String secondPlayer = 'Bob',
  String? winner,
}) => GameScore(
  date: DateTime(2026, 9, 1, 15, 50),
  firstPlayer: firstPlayer,
  secondPlayer: secondPlayer,
  winner: winner ?? Winner.first.name,
  firstRoundFirstPlayerPoints: 33,
  firstRoundSecondPlayerPoints: 12,
  secondRoundFirstPlayerPoints: 21,
  secondRoundSecondPlayerPoints: 40,
);

void main() {
  Future<void> pumpCard(WidgetTester tester, GameScore score) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.data,
        home: Scaffold(body: ScoreCardWidget(score: score)),
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

  ColorFilter crownFilter(WidgetTester tester, String key) => tester
      .widget<SvgPicture>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(SvgPicture),
        ),
      )
      .colorFilter!;

  group('ScoreCardWidget', () {
    testWidgets(
      '''
      Given the app theme
      When a score card is rendered
      Then it is a dark panel with the shared olive hairline and corners
      ''',
      (tester) async {
        // When
        await pumpCard(tester, buildScore());

        // Then
        final card = paintedCard(tester);
        expect(card.color, AppTheme.panel);
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.side.color, AppTheme.olive);
        expect(shape.side.width, 1);
        expect(shape.borderRadius, const BorderRadius.all(Radius.circular(4)));
      },
    );

    testWidgets(
      '''
      Given the global dark card theme
      When a score card is rendered
      Then the card does not wrap its content in a theme of its own
      ''',
      (tester) async {
        // When
        await pumpCard(tester, buildScore());

        // Then
        expect(
          find.descendant(
            of: find.byType(ScoreCardWidget),
            matching: find.byType(Theme),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      '''
      Given the app theme
      When a score card is rendered
      Then every line of text is readable against the card
      ''',
      (tester) async {
        // Given
        const cardColor = AppTheme.panel;

        // When
        await pumpCard(tester, buildScore());

        // Then
        final paragraphs = tester.renderObjectList<RenderParagraph>(
          find.byType(RichText),
        );
        expect(paragraphs, isNotEmpty);
        for (final paragraph in paragraphs) {
          final color = paragraph.text.style?.color;
          expect(
            color,
            isNotNull,
            reason: 'text "${paragraph.text.toPlainText()}" has no color',
          );
          expect(
            _contrastRatio(color!, cardColor),
            greaterThanOrEqualTo(4.5),
            reason:
                'text "${paragraph.text.toPlainText()}" is not readable on the card',
          );
        }
      },
    );

    testWidgets(
      '''
      Given a score card
      When it is rendered
      Then the winner line is centered under the players and reads larger than the date
      ''',
      (tester) async {
        // When
        await pumpCard(tester, buildScore(winner: Winner.first.name));

        // Then
        final winnerFinder = find.textContaining(ScoresStrings.winner);
        final winnerText = tester.widget<Text>(winnerFinder);
        final dateFinder = find.textContaining('2026');
        final dateText = tester.widget<Text>(dateFinder);
        expect(
          winnerText.style!.fontSize,
          greaterThan(dateText.style!.fontSize!),
        );
        final cardCenterX = tester.getCenter(find.byType(Card)).dx;
        expect(tester.getCenter(winnerFinder).dx, closeTo(cardCenterX, 1));
      },
    );

    testWidgets(
      '''
      Given a game won by the first player
      When the card is rendered
      Then the winner wears a gold crown and the loser an olive one
      ''',
      (tester) async {
        // When
        await pumpCard(tester, buildScore(winner: Winner.first.name));

        // Then
        expect(
          crownFilter(tester, 'score-card-crown-first'),
          const ColorFilter.mode(AppTheme.gold, BlendMode.srcIn),
        );
        expect(
          crownFilter(tester, 'score-card-crown-second'),
          const ColorFilter.mode(AppTheme.olive, BlendMode.srcIn),
        );
      },
    );

    testWidgets(
      '''
      Given a game won by the second player
      When the card is rendered
      Then the gold crown moves to the second player
      ''',
      (tester) async {
        // When
        await pumpCard(tester, buildScore(winner: Winner.second.name));

        // Then
        expect(
          crownFilter(tester, 'score-card-crown-first'),
          const ColorFilter.mode(AppTheme.olive, BlendMode.srcIn),
        );
        expect(
          crownFilter(tester, 'score-card-crown-second'),
          const ColorFilter.mode(AppTheme.gold, BlendMode.srcIn),
        );
      },
    );

    testWidgets(
      '''
      Given a score saved without player names
      When the card is rendered
      Then placeholder names are shown
      ''',
      (tester) async {
        // When
        await pumpCard(tester, buildScore(firstPlayer: '', secondPlayer: '  '));

        // Then
        expect(find.text(ScoresStrings.player1), findsWidgets);
        expect(find.text(ScoresStrings.player2), findsWidgets);
      },
    );

    testWidgets(
      '''
      Given a score won by an unnamed player
      When the card is rendered
      Then the winner line shows the placeholder name
      ''',
      (tester) async {
        // When
        await pumpCard(
          tester,
          buildScore(
            firstPlayer: '',
            secondPlayer: 'Bob',
            winner: Winner.first.name,
          ),
        );

        // Then
        expect(
          find.text('${ScoresStrings.winner}${ScoresStrings.player1}'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '''
      Given long player names
      When the card is rendered
      Then the names stay on one line and ellipsize
      ''',
      (tester) async {
        // Given
        const firstPlayer = 'A very long player name that will not fit';
        const secondPlayer = 'Another very long player name that will not fit';

        // When
        await pumpCard(
          tester,
          buildScore(firstPlayer: firstPlayer, secondPlayer: secondPlayer),
        );

        // Then
        final names = [
          ...tester.widgetList<Text>(find.text(firstPlayer)),
          ...tester.widgetList<Text>(find.text(secondPlayer)),
        ];
        expect(names, isNotEmpty);
        for (final name in names) {
          expect(name.maxLines, 1);
          expect(name.overflow, TextOverflow.ellipsis);
        }
      },
    );
  });
}
