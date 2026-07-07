import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';

void main() {
  final date = DateTime(2026, 7, 6, 12, 30);

  group('GameScore', () {
    group('`toMap` / `fromMap`', () {
      test(
        '''
      Given a fully populated `GameScore`
      When `toMap` then `fromMap` are called
      Then all fields survive
      ''',
        () {
          // Given
          final score = GameScore(
            date: date,
            firstPlayer: 'Alice',
            secondPlayer: 'Bob',
            winner: 'first',
            firstRoundFirstPlayerPoints: 10,
            secondRoundFirstPlayerPoints: 20,
            thirdRoundFirstPlayerPoints: 30,
            firstRoundSecondPlayerPoints: 11,
            secondRoundSecondPlayerPoints: 21,
            thirdRoundSecondPlayerPoints: 31,
          );

          // When
          final restored = GameScore.fromMap(score.toMap());

          // Then
          expect(restored.date, date);
          expect(restored.firstPlayer, 'Alice');
          expect(restored.secondPlayer, 'Bob');
          expect(restored.winner, 'first');
          expect(restored.firstRoundFirstPlayerPoints, 10);
          expect(restored.secondRoundFirstPlayerPoints, 20);
          expect(restored.thirdRoundFirstPlayerPoints, 30);
          expect(restored.firstRoundSecondPlayerPoints, 11);
          expect(restored.secondRoundSecondPlayerPoints, 21);
          expect(restored.thirdRoundSecondPlayerPoints, 31);
        },
      );

      test(
        '''
      Given null round points
      When round-tripped through `toMap`/`fromMap`
      Then nulls are preserved
      ''',
        () {
          // Given
          final score = GameScore(
            date: date,
            firstPlayer: 'Alice',
            secondPlayer: 'Bob',
            winner: 'tie',
          );

          // When
          final restored = GameScore.fromMap(score.toMap());

          // Then
          expect(restored.firstRoundFirstPlayerPoints, isNull);
          expect(restored.thirdRoundSecondPlayerPoints, isNull);
        },
      );

      test(
        '''
      Given a `GameScore`
      When `toMap` is called
      Then `date` is stored as `millisecondsSinceEpoch`
      ''',
        () {
          // Given
          final score = GameScore(
            date: date,
            firstPlayer: 'A',
            secondPlayer: 'B',
            winner: 'first',
          );

          // When / Then
          expect(score.toMap()['date'], date.millisecondsSinceEpoch);
        },
      );
    });
  });
}
