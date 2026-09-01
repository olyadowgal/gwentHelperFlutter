import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/domain/models/game_score.dart';
import 'package:gwent_helper_flutter/domain/models/winner.dart';

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
          expect(restored.id, score.id);
        },
      );

      test(
        '''
      Given a map without `id`
      When `fromMap` is called
      Then a legacy id is derived from `date`
      ''',
        () {
          // Given
          final map = {
            'date': date.millisecondsSinceEpoch,
            'first_player': 'Alice',
            'second_player': 'Bob',
            'winner': 'first',
          };

          // When
          final restored = GameScore.fromMap(map);

          // Then
          expect(restored.id, 'legacy-${date.millisecondsSinceEpoch}');
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

    group('winner display', () {
      GameScore scoreWith({required String winner}) => GameScore(
        date: date,
        firstPlayer: 'Alice',
        secondPlayer: 'Bob',
        winner: winner,
      );

      test(
        '''
      Given winner stored as `Winner.first` name
      When display helpers are read
      Then first player won and the label is Alice
      ''',
        () {
          // Given
          final score = scoreWith(winner: Winner.first.name);

          // Then
          expect(score.firstPlayerWon, isTrue);
          expect(score.secondPlayerWon, isFalse);
          expect(score.displayedWinner(tieLabel: 'Tie'), 'Alice');
        },
      );

      test(
        '''
      Given winner stored as `Winner.second` name
      When display helpers are read
      Then second player won and the label is Bob
      ''',
        () {
          // Given
          final score = scoreWith(winner: Winner.second.name);

          // Then
          expect(score.firstPlayerWon, isFalse);
          expect(score.secondPlayerWon, isTrue);
          expect(score.displayedWinner(tieLabel: 'Tie'), 'Bob');
        },
      );

      test(
        '''
      Given winner stored as `Winner.tie` name
      When display helpers are read
      Then neither player won and the label is the tie label
      ''',
        () {
          // Given
          final score = scoreWith(winner: Winner.tie.name);

          // Then
          expect(score.firstPlayerWon, isFalse);
          expect(score.secondPlayerWon, isFalse);
          expect(score.displayedWinner(tieLabel: 'Tie'), 'Tie');
        },
      );

      test(
        '''
      Given winner stored as the first player's name
      When display helpers are read
      Then first player won
      ''',
        () {
          // Given
          final score = scoreWith(winner: 'Alice');

          // Then
          expect(score.firstPlayerWon, isTrue);
          expect(score.secondPlayerWon, isFalse);
          expect(score.displayedWinner(tieLabel: 'Tie'), 'Alice');
        },
      );

      test(
        '''
      Given a player named first who lost
      When winner is `Winner.second` name
      Then the first player is not treated as winner
      ''',
        () {
          // Given
          final score = GameScore(
            date: date,
            firstPlayer: 'first',
            secondPlayer: 'Bob',
            winner: Winner.second.name,
          );

          // Then
          expect(score.firstPlayerWon, isFalse);
          expect(score.secondPlayerWon, isTrue);
          expect(score.displayedWinner(tieLabel: 'Tie'), 'Bob');
        },
      );
    });
  });
}
