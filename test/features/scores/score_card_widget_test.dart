import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  group('ScoreCardWidget', () {
    testWidgets(
      '''
      Given the app theme
      When a score card is rendered
      Then every line of text is readable against the card
      ''',
      (tester) async {
        // Given
        final cardColor = AppTheme.data.cardTheme.color!;

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
  });
}
